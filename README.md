# Handy-bioinformatics-scripts
Handy bioinformatics scripts for operations I find myself needing to perform frequently. Currently working on modularising some of the pipelines I have created this year so that I (or others) can reuse everything for future projects, including on platforms other than the Cambridge HPC. The hope is that this will also make onboarding easier for new lab members with little to no bioinformatics experience, since so many labs have data that would be great for undergraduate or 1-year master's projects, but the initial bioinformatics learning curve can often be prohibitively steep.

- `VCF_QC` contains scripts for getting and plotting diagnostic stats from VCF files to inform filtering decisions
- `Download_NCBI` contains scripts for downloading sequencing data from the NCBI database
- `Filter_map_reads` contains a modular snakemake pipeline for trimming, filtering and mapping short reads to a reference genome. WIP
