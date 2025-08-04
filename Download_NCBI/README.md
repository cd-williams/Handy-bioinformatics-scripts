# Download_NCBI

Workflow for downloading sequencing data from NCBI. Usage is:

```
sbatch -A [billing account] --cpus-per-task [how many CPUs for bgzip compression] -p [partition] -a [1-x where x is No. of samples] get_fastqs.sh [path to .txt file containing a list of SRR accessions]
```

You can also tweak any of the other settings for SLURM if you want.