#!/bin/bash
#SBATCH -J download_fastq
#SBATCH -o logs/logs/get_fastqs_%a.log
#SBATCH -e logs/error/get_fastqs_%a.err
#SBATCH --time=01:00:00
#SBATCH --mail-type ALL

# See README for script usage
# This script uses sra-toolkit to download .fastq files from NCBI and compress them in parallel

# Allow the script to use a conda environment (or in my case mamba)
eval "$(conda shell.bash hook)"
source $CONDA_PREFIX/etc/profile.d/mamba.sh

# Activate the download_NCBI environment
mamba activate download_NCBI

# Use a SLURM array to process all the samples in parallel
accessions_list=$1

accession=$(cat ${accessions_list} | head -n $SLURM_ARRAY_TASK_ID | tail -n 1) # get this sample

# Get the .sra file from NCBI
prefetch ${accession}

# Check it downloaded ok. If any of your samples can't be processed downstream or look suspicious later, check this file.
vdb-validate ${accession}/${accession}.sra > ${accession}/md5.txt 2>&1

# Convert to .fastq
fasterq-dump --threads $SLURM_CPUS_PER_TASK --progress -O  ${accession}/ ${accession}

# Compress in parallel using bgzip
bgzip --threads $SLURM_CPUS_PER_TASK ${accession}/${accession}_1.fastq
bgzip --threads $SLURM_CPUS_PER_TASK ${accession}/${accession}_2.fastq

# Delete the .sra file since it can be > 1GB and we don't need it anymore
rm ${accession}/${accession}.sra
