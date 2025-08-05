# Handy-bioinformatics-scripts
Handy bioinformatics scripts for operations I find myself needing to perform frequently. Currently working on modularising my population genetics pipelines so that I (or others) can reuse everything for future projects, including on platforms other than the Cambridge HPC.

- `VCF_QC` contains scripts for getting and plotting diagnostic stats from VCF files to inform filtering decisions
- `Download_NCBI` contains scripts for downloading sequencing data from the NCBI database
- `Filter_map_reads` contains a modular snakemake pipeline for trimming, filtering and mapping short reads to a reference genome. WIP
