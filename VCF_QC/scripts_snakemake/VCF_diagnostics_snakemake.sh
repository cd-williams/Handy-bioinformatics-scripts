#!/bin/bash

# This script takes a compressed, tbi-indexed VCF as an input, and outputs diagnostic statistics
# It is designed to be used as part of a snakemake pipeline
# A required parameter is the output directory for the stats files
# Requires vcftools (sadly no multithreading :( )


# Allele frequency for each variant
vcftools --gzvcf ${snakemake_input[VCF]} --freq2 --out ${snakemake_params[outdir]} --max-alleles 2

# Mean depth of coverage per individual
vcftools --gzvcf ${snakemake_input[VCF]} --depth --out ${snakemake_params[outdir]}

# Mean depth of coverage for each site
vcftools --gzvcf ${snakemake_input[VCF]} --site-mean-depth --out ${snakemake_params[outdir]}

# Quality score for each site
vcftools --gzvcf ${snakemake_input[VCF]} --site-quality --out ${snakemake_params[outdir]}

# Proportion of missing data per individual
vcftools --gzvcf ${snakemake_input[VCF]} --missing-indv --out ${snakemake_params[outdir]}

# Proportion of missing data per site
vcftools --gzvcf ${snakemake_input[VCF]} --missing-site --out ${snakemake_params[outdir]}

# Individual heterozygosity
vcftools --gzvcf ${snakemake_input[VCF]} --het --out ${snakemake_params[outdir]}

# Genotype depth
vcftools --gzvcf ${snakemake_input[VCF]} --geno-depth --out ${snakemake_params[outdir]}

# Genotype quality
vcftools --gzvcf ${snakemake_input[VCF]} --extract-FORMAT-info GQ --out ${snakemake_params[outdir]}
