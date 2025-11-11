Tools for manipulating BEAGLE genotype likelihood files produced by ANGSD

Contents
- `BAMpath2IndSample.sh` takes a txt file with one BAM filepath per line (that you provided to ANGSD) and returns a TSV with sample names and the corresponding ANGSD IndID
- `select_individuals.sh` takes a compressed BEAGLE file, a txt file with one sample name per line, and a TSV mapping file produced by `BAMpath2IndSample.sh` and selects those samples from the BEAGLE file
