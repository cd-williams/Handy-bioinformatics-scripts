#!/bin/bash

# Script that takes a txt file with a list of BAM filepaths and returns a TSV with Indxxx and the sample name (useful for filtering BEAGLE files)
############################################################
# Take the inputs and assign them to variables             #
############################################################


while getopts i:o: flag
do
    case $flag in
        i) bam_paths=$OPTARG;; # txt file with one BAM filepath per line
        o) output_prefix=$OPTARG;; # prefix for the output TSV file
        \?) echo "Error: invalid option"
            exit;;
    esac
done


############################################################
# Creating the TSV                                         #
############################################################

# We use a while loop that goes through each line in $bam_paths

i=0

# opens the while loop. 
#IFS= temporarily sets internal field separator to nothing (so eg spaces in file paths don't mess this up)
# read -r line takes the first line from standard input, assigns it to $line, and then moves the input pointer to the end of that line. -r ignores special characters (eg \t)
while IFS= read -r line; do
    filename=$(basename $line) # Drop all the folders, just get the filename
    sample="${filename%%.*}" # Drop any .bam, .rmd.bam etc
    echo -e "${sample}\tInd${i}" >> "${output_prefix}.tsv"
    ((i++))
done < "$bam_paths" # make the loop take $bam_paths as its standard input



