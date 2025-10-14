#!/bin/bash

# Script that takes a TSV of SRR accessions and sample names as input
# and returns a YAML config file for the snakemake pipeline


############################################################
# Take the inputs and assign them to variables             #
############################################################
# Get the options

while getopts a:d:r: flag
do
    case $flag in
        a) accessions=$OPTARG;; # TSV with the accessions
        d) sequencing_dir=$OPTARG;; # Directory where sequencing data is stored
        r) reference=$OPTARG;; # Reference genome
        \?) echo "Error: invalid option"
            exit;;
    esac
done


############################################################
# Creating the config file                                 #
############################################################

# 1. Add the header
echo "#----------------------------------------------------------------------------" > config.yaml
echo "### FILEPATHS ###" >> config.yaml
echo "#----------------------------------------------------------------------------" >> config.yaml

# 2. Add the reference genome
echo "" >> config.yaml # there are more elegant ways to do this using \n or similar but they aren't stable across all OS
echo "# Reference genome" >> config.yaml
echo "reference: ${reference}" >> config.yaml
echo "" >> config.yaml

# 3. Loop through all the accessions in the TSV to add prefixes, forward and reverse reads to the config
#    We will do this by saving them to two different text files, and then concatenating both files to the config
echo "# Forward read filepaths" > config_forward.txt
echo "forward:" >> config_forward.txt

echo "# Reverse read filepaths" > config_reverse.txt
echo "reverse:" >> config_reverse.txt

echo "# Sample prefixes" > config_prefixes.txt
echo "prefix:" >> config_prefixes.txt

for i in $(seq 1 $(cat $accessions | wc -l))
do
    this_accession=$(cat $accessions | cut -f 1 | head -n $i | tail -n 1)
    this_id=$(cat $accessions | cut -f 2 | head -n $i | tail -n 1)

    echo -e "  ${this_id}: ${this_id}" >> config_prefixes.txt
    echo -e "  ${this_id}: ${sequencing_dir}${this_accession}/${this_accession}_1.fastq.gz" >> config_forward.txt
    echo -e "  ${this_id}: ${sequencing_dir}${this_accession}/${this_accession}_2.fastq.gz" >> config_reverse.txt
done

cat config_prefixes.txt >> config.yaml
echo "" >> config.yaml
cat config_forward.txt >> config.yaml
echo "" >> config.yaml
cat config_reverse.txt >> config.yaml

rm config_*.txt




