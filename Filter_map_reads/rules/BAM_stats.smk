# Rule to get diagnostic stats from our final BAM files

rule BAM_stats:
    input:
        "BAM_files/{sample}.rmd.bam"
    output:
        stats = "BAM_files/stats/{sample}.stats",
        flagstat = "BAM_files/stats/{sample}.flagstats"
    conda:
        config["default_env"]
    shell:
        "samtools stats {input} > {output.stats}; "
        "samtools flagstat {input} > {output.flagstat}"

# No need for multithreading as this step is normally pretty quick