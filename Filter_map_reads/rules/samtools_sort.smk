# Snakemake rule that sorts BAM files


rule samtools_sort:
    input:
        "mapped_reads/{sample}.bam"
    output:
        temp("sorted_reads/{sample}.bam")
    threads: 10
    conda:
        config["default_env"]
    log:
        "logs/samtools_sort/{sample}.log"
    shell:
        "(samtools sort -T sorted_reads/{wildcards.sample} -@ {threads} -O bam {input} > {output}) 2> {log}"

# -T is the prefix for any intermediate files