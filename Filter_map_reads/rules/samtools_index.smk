# Rule to index BAM file
# We need to do this more than once in our workflow and I think there ought to be an elegant way to do that but I haven't worked it out yet
# So for now each time we do it is a different rule. Watch this space.

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
