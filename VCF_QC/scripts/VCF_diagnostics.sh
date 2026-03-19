#!/bin/bash

# This script takes a compressed, tbi-indexed VCF as an input, and outputs diagnostic statistics
# It is designed to be used as part of a snakemake pipeline
# A required parameter is the output directory for the stats files
# Requires vcftools (sadly no multithreading :( )

while getopts v:o: flag
do
    case $flag in
        v) vcf=$OPTARG;; # the VCF
        o) outdir=$OPTARG;; # output directory
        \?) echo "Error: invalid option"
            exit;;
    esac
done

# Allele frequency for each variant
echo "Allele frequency"
vcftools --gzvcf ${vcf} --freq2 --out ${outdir} --max-alleles 2 --min-alleles 2

# Mean depth of coverage per individual
echo "Mean individual depth"
vcftools --gzvcf ${vcf} --depth --out ${outdir}

# Mean depth of coverage for each site
echo "Mean depth for each site"
vcftools --gzvcf ${vcf} --site-mean-depth --out ${outdir}

# Quality score for each site
echo "Quality score for each site"
vcftools --gzvcf ${vcf} --site-quality --out ${outdir}

# Proportion of missing data per individual
echo "proportion of missing data for each individual"
vcftools --gzvcf ${vcf} --missing-indv --out ${outdir}

# Proportion of missing data per site
echo "proportion of missing data for each site"
vcftools --gzvcf ${vcf} --missing-site --out ${outdir}

# Individual heterozygosity
echo "individual heterozygosity"
vcftools --gzvcf ${vcf} --het --out ${outdir}

# Genotype depth
echo "Genotype depth"
vcftools --gzvcf ${vcf} --geno-depth --out ${outdir}

# Genotype quality
echo "Genotype quality"
vcftools --gzvcf ${vcf} --extract-FORMAT-info GQ --out ${outdir}
