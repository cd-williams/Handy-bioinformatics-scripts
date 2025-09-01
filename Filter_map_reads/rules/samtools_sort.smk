# Snakemake rule that sorts BAM files
# We will need to do this twice in our workflow (once directly after mapping and once after removing PCR duplicates)
# but I haven't worked out an elegant way to do that with just one rule yet

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