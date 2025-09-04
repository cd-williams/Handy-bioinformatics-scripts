# Rule to index BAM file
# This rule handles every BAM indexing step in the pipeline, but unfortunately there isn't an elegant way to do that using wildcards
# since we want the outputs from some steps to be temporary while we want others to be permament

rule samtools_index:
    input:
        "sorted_reads/{sample}.bam"
    output:
        temp("sorted_reads/{sample}.bam.bai")
    conda:
        config["default_env"]
    log:
        "logs/samtools_index/{sample}.log"
    shell:
        "(samtools index {input}) 2> {log}"

# This is normally pretty quick, I will add support for multithreading if it ever becomes prohibitive
