#!/bin/bash

# This script takes a compressed, tbi-indexed VCF as an input, and outputs a compressed, tbi-indexed VCF containing a random subsample of sites
# It is designed to be used as a step in a snakemake pipeline
# Supports multithreading (but I don't think vcflib does so that may be a bit of a bottleneck here)
# Requires the sampling rate as a parameter
# Requires bcftools, vcflib and bgzip

bcftools view --threads ${snakemake[threads]} ${snakemake_input[VCF]} | vcfrandomsample -r ${snakemake_params[rate]} | bgzip \
    --threads ${snakemake[threads]} -o ${snakemake_output[VCF]}

bcftools index --threads ${snakemake[threads]} --tbi ${snakemake_output[VCF]}

