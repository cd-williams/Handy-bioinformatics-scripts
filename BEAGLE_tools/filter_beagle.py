# Script for selecting a range of sites and individuals from a BEAGLE genotype likelihood file produced by ANGSD
"""
filter_beagle.py — Filter ANGSD beagle.gz files by sites and/or individuals.

Usage:
    python filter_beagle.py -i input.beagle.gz -o output.beagle.gz [options]

Options:
    -i, --input       Input .beagle.gz file
    -o, --output      Output .beagle.gz file
    -S, --samples     File with individual names to keep (one per line)
    -R, --regions     Region(s) to keep. Accepts:
                        - A file (one region per line)
                        - A comma-separated list of regions on the command line
                      Region formats supported (as in bcftools):
                        chr              whole chromosome
                        chr:pos          single site
                        chr:start-end    inclusive range
    -t, --threads     Number of threads (default: 1)
    --chunk-size      Lines per chunk (default: 10000)
"""

import gzip
import sys
import argparse
import os
from concurrent.futures import ProcessPoolExecutor
from itertools import islice


# ---------------------------------------------------------------------------
# Parsing the --regions option (ie working out if it is a file or a string)
# ---------------------------------------------------------------------------

# Parsing individual lines
def parse_region_string(region):
    """
    Parse a single bcftools-style region string into (chrom, start, end).
    start and end are both inclusive, 1-based indexing. If nothing is passed to this arg then it will use all the sites in the supplied .beagle.gz.

    Accepted formats:
        chr              -> (chr, None, None)
        chr:pos          -> (chr, pos, pos)
        chr:start-end    -> (chr, start, end)

    Returns a tuple of (chrom, start, end) - start and end may be None
    """
    # 1. Whole chromosome
    if ":" not in region:
        return (region, None, None)

    chrom, rest = region.split(":", 1)                                                           # Split at ":" into a list with two elements

    # 2. Single site
    if "-" not in rest:
        pos = int(rest.replace(",", ""))                                                         # Removing any commas (eg if they input 1:100,000)
        return (chrom, pos, pos)                                                                 # Would return 1, 100000, 100000

    # 3. Range
    start_str, end_str = rest.split("-", 1)
    start = int(start_str.replace(",", "")) if start_str else None
    end   = int(end_str.replace(",", ""))   if end_str   else None
    return (chrom, start, end)

# Parsing the file or comma separated list
def parse_regions_input(regions_arg):
    """
    Accept either a file path or a comma-separated region string.
    Returns a list of (chrom, start, end) tuples.
    """
    if os.path.isfile(regions_arg):                                                              # If it's a file
        with open(regions_arg) as f:
            raw = [line.strip() for line in f if line.strip() and not line.startswith("#")]      # Remove whitespace, and skip blank lines or those starting with #
    else:                                                                                        # If it's a comma-separated list
        raw = [r.strip() for r in regions_arg.split(",") if r.strip()]

    return [parse_region_string(r) for r in raw]


def build_site_filter(regions):
    """
    Pre-process regions into:
      - exact_sites: set of "chr_pos" strings  (for single-site lookups, O(1))
      - ranges:      dict chrom -> list of (start, end) tuples
    Returns a function site_passes(marker) -> bool.
    """
    exact_sites = set()
    ranges = {}  # dict that maps chrom -> [(start, end), ...]

    for chrom, start, end in regions:
        if start is None and end is None:                                               # Whole chromosome — use sentinel range (inf is a boundary condition)
            ranges.setdefault(chrom, []).append((0, float("inf")))
        elif start == end:                                                              # Single site
            exact_sites.add(f"{chrom}_{start}")                                         # Putting it in the same format as the ANGSD POS column (ie 1_1312)
        else:                                                                           # Range (eg 1:1234-5678)
            ranges.setdefault(chrom, []).append((start, end))                           # Setdefault returns the existing entry for that chrom if it exists, or an empty list if it doesn't

    def site_passes(marker):                                                            # Takes an ANGSD POS entry and returns TRUE or FALSE if it passes
        # marker format: "chr_pos"
        if marker in exact_sites:
            return True
        # Split on last underscore to handle chr names like "chr1_NCBI_Ara_tha"
        idx = marker.rfind("_")                                                         # Find the last occurrence of "_" and return its index in the string
        if idx == -1:                                                                   # If you don't find any (ie marker isn't a valid CHROM_POS)
            return False
        chrom = marker[:idx]                                                            # Gets the chromosome name
        try:
            pos = int(marker[idx + 1:])                                                 # Grabs the position
        except ValueError:                                                              # If it's not a valid CHROM_POS
            return False
        for s, e in ranges.get(chrom, []):                                              # Returns dict entry for that chrom if it exists, empty list if it doesn't (for loop doesn't execute)
            if s <= pos <= e:                                                           # If it's in the range
                return True
        return False

    return site_passes


# ---------------------------------------------------------------------------
# Picking which columns (individuals) to keep (parsing of --samples is done in main)
# ---------------------------------------------------------------------------
# Returs a list of integers corresponding to which columns to keep
def load_keep_cols(header_fields, keep_inds):                                       # header_fields is a LIST of all the column titles, keep_inds is a SET of sample names
    """Return sorted list of column indices to retain."""
    ind_names = header_fields[3::3]                                                 # List of IndIDs from header (every 3rd column name starting from column 3)
    keep_cols = [0, 1, 2]                                                           # Always keep the first 3 columns (POS, REF, ALT)
    for i, name in enumerate(ind_names):                                            # Enumerate is 0-indexed so the 3 + i*3 makes sense
        if name in keep_inds:
            base = 3 + i * 3
            keep_cols += [base, base + 1, base + 2]                                 # Concatenating lists
    if len(keep_cols) == 3:                                                         # If it didn't find any individuals
        sys.exit(
            "ERROR: No individuals from -S were found in the beagle header. "
            "Check that sample names match exactly."
        )
    return keep_cols


# ---------------------------------------------------------------------------
# Chunk processing (runs in worker processes)
# ---------------------------------------------------------------------------

def process_chunk(args):
    """
    Filter a list of raw line strings.
    Accepts a tuple so it is picklable for ProcessPoolExecutor.
    """
    chunk, keep_cols, site_filter_regions = args                                    # args is a tuple
                                                                                    # chunk is the portion of the file, keep_cols is a list of integers
                                                                                    # site_filter_regions is a list of tuples (chrom, pos, pos) (where pos can be None)

    # Rebuild site_passes inside the worker (since lambdas aren't picklable)
    if site_filter_regions is not None:                                             # ie if we are filtering sites, not just individuals
        site_passes = build_site_filter(site_filter_regions)                        # Returns a function that takes a CHROM_POS and returns true if it's to be kept, otherwise false
    else:
        site_passes = None

    out = []
    for line in chunk:
        fields = line.rstrip("\n").split("\t")                                      # Remove trailing \n and split into list
        if site_passes is not None and not site_passes(fields[0]):                  # If the site is to be kept
            continue
        if keep_cols is not None:                                                   # If we're filtering individuals
            out.append("\t".join(fields[c] for c in keep_cols))                     # Just pick those columns
        else:
            out.append("\t".join(fields))

    return "\n".join(out) + ("\n" if out else "")                                   # Return the processed row


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# Args are the input file and the chunk size
def ichunks(iterable, size):
    it = iter(iterable)                                                          # Creating this outside the while loop means each iteration of the loop moves +chunksize from the last one
    while True:
        chunk = list(islice(it, size))                                           # The chunk of the beagle.gz file
        if not chunk:
            break
        yield chunk


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
# Parse arguments
def parse_args():
    p = argparse.ArgumentParser(
        description="Filter ANGSD beagle.gz files by sites and/or individuals.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("-i", "--input",      required=True,            help="Input .beagle.gz")
    p.add_argument("-o", "--output",     required=True,            help="Output .beagle.gz")
    p.add_argument("-S", "--samples",    default=None,             help="File of individual names to keep")
    p.add_argument("-R", "--regions",    default=None,
                   help="Regions to keep: a file or comma-separated list (e.g. 1:1000-2000,2:500-900)")
    p.add_argument("-t", "--threads",    default=1,   type=int,    help="Threads (default: 1)")
    p.add_argument("--chunk-size",       default=10000, type=int,  help="Lines per chunk (default: 10000)")
    return p.parse_args()


def main():
    args = parse_args()

    # --- Load filters ---
    keep_inds = None                                                                            # Individuals to keep (default None means keep all)
    if args.samples:
        with open(args.samples) as f:
            keep_inds = set(line.strip() for line in f if line.strip())                         # Set of individuals to keep

    site_filter_regions = None                                                                  # passed to workers; None means keep all
    if args.regions:
        site_filter_regions = parse_regions_input(args.regions)                                 # Returns a list of tuples (chrom, pos, pos)

    with gzip.open(args.input, "rt") as fin, gzip.open(args.output, "wt") as fout:              # Decompress on the fly (r = read, w=write, t=text (as opposed to binary))

        # Parse the header
        header = fin.readline().rstrip("\n").split("\t")                                        # Reads the first line, removes trailing \n, splits at \t. !!Moves the iterator on to the next line!!

        # Select columns to keep
        keep_cols = None                                            
        if keep_inds is not None:
            keep_cols = load_keep_cols(header, keep_inds)                                       # Returns a list of integers corresponding to which columns to keep (0-indexed)
            fout.write("\t".join(header[c] for c in keep_cols) + "\n")                          # Write the new header
        else:
            fout.write("\t".join(header) + "\n")                                                # If you're not filtering individuals, write the old header

        # Implementing parallelisation
        worker_args = (                                                                         # Creates a GENERATOR object (where you can call the next tuple using next())
            (chunk, keep_cols, site_filter_regions)                                             # This prevents storing all the chunks in memory at once
            for chunk in ichunks(fin, args.chunk_size)                                          # Chunk is the section of the file we want this thread to process
        )

        # Preserve output order by collecting futures in submission order
        with ProcessPoolExecutor(max_workers=args.threads) as pool:
            futures = [pool.submit(process_chunk, a) for a in worker_args]                      # sends a to process_chunk() and creates a "future" ie placeholder
            for fut in futures:                                                                 # iterating over futures in submission order preserves the order of the sites
                result = fut.result()
                if result:
                    fout.write(result)


if __name__ == "__main__":
    main()