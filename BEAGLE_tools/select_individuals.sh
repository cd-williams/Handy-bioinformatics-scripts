#!/bin/bash
# Script that takes a beagle.gz file, a list of sample names, and a mapping of sample->Indxxx and returns a beagle.gz file for that subset of individuals

############################################################
# Take the inputs and assign them to variables             #
############################################################


while getopts b:o:s:m:t: flag
do
    case $flag in
        b) beagle=$OPTARG;; # input beagle.gz file
        o) output_prefix=$OPTARG;; # prefix for the output beagle.gz file
        s) sample_list=$OPTARG;; # txt file with one sample per line
        m) mapping=$OPTARG;; # TSV file where column 1 is sample names and column 2 is Indxxx
        t) threads=$OPTARG;; # Number of threads for bgzip
        \?) echo "Error: invalid option"
            exit;;
    esac
done

############################################################
# Subsetting the beagle.gz                                 #
############################################################

# Makes sure our script returns an error message if any line fails
# -e causes bash to immediately exit if any command has a non-zero exit status
# -u causes bash to immediately exit if you reference a variable you haven't previously defined
# -o pipefail causes the return code of any failed command to be the return code of the whole pipeline
set -euo pipefail

# Step 1. create an array from the mapping TSV ------------------------------------------------
# Create an empty associative array
declare -A map

# Detect delimiter in $mapping (in case the user created their own). Either tab or space
delimiter=$(head -n1 "$mapping" | grep -q $'\t' && echo $'\t' || echo ' ')

# Load mapping into the array
while IFS="$delimiter" read -r sample indid _ || [[ -n "$sample" ]]; do
    sample=$(echo "$sample" | tr -d '\r' | xargs)
    indid=$(echo "$indid" | tr -d '\r' | xargs)
    [[ -n "$sample" && -n "$indid" ]] && map["$sample"]="$indid"
done < "$mapping"

echo "LOG: contents of map:" >> "${output_prefix}.log"
for key in "${!map[@]}"; do
    echo "Sample: '$key' -> IndID: '${map[$key]}'" >> "${output_prefix}.log"
done

# Step 2. Get the list of Indxxx to keep -------------------------------------------------------

inds=() # initialise a regular indexed array

while IFS= read -r s; do
    if [[ -n "${map[$s]:-}" ]]; then # check the sample exists in the mapping. :- avoids set -u throwing an error (since we just want a warning in this instance)
        inds+=("${map[$s]}")
    else
        echo "WARNING: sample $s not found in mapping file" >&2 # print to stderr
    fi
done < "$sample_list"

# If no Indxxx were successfully found, print a message to stderr and exit
if [ ${#inds[@]} -eq 0 ]; then
    echo "ERROR: No matching sample names found in mapping file" >&2
    exit 1
fi


# Step 3. Determine which beagle columns to extract -------------------------------------------------------------------
echo "LOG: beagle file = '$beagle'" >> "${output_prefix}.log"
echo "LOG: inds = ${inds[*]}" >> "${output_prefix}.log"


# Extract header
header=$(zcat "$beagle" | head -n 1 || true) 

# Loop through inds
cols="1,2,3" # we always want the first 3 columns (marker, allele1, allele2)

for id in "${inds[@]}"; do
    pos=$(echo "$header" | tr '\t' '\n' | grep -n "^${id}$" | cut -d: -f1 | paste -sd, -)
    if [ -z "$pos" ]; then
        echo "Warning: no columns found for $id in Beagle file" >&2
    else
        cols="${cols},${pos}"
    fi
done

echo "LOG: final cols = $cols" >> "${output_prefix}.log"


# Step 4. Extract relevant columns and write to a new beagle file

bgzip -dc -@ "$threads" "$beagle" | \
awk -v cols="$cols" 'BEGIN {
    n = split(cols, c, ",")
}
{
    out = ""
    for (i = 1; i <= n; i++) {
        out = out (i == 1 ? "" : "\t") $c[i]
    }
    print out
}' | bgzip -@ "$threads" > "${output_prefix}.beagle.gz"

echo "Done"