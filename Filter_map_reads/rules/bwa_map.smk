# Snakemake rule that uses bwa to align reads to a reference genome

rule bwa_map:
    input:
        ref = config["reference"],
        fq1 = "trimmed_reads/{sample}.fastp.1.fq.gz",
        fq2 = "trimmed_reads/{sample}.fastp.2.fq.gz"
    output:
        bam = temp("mapped_reads/{sample}.bam")
    params:
        prefix = lambda wildcards: config["prefix"][wildcards.sample],
        rg1="@RG\\tPL:Illumina\\tSM:", # NOTE make these customisable once you are confident the modular pipeline is working
        rg2="\\tID:"
    conda:
        config["default_env"]
    log:
        "logs/bwa_map/{sample}.log"
    shell:
        "(bwa mem -M -R '{params.rg1}{params.prefix}{params.rg2}{params.prefix}' "
        "-t {threads} {input.ref} {input.fq1} {input.fq2} | "
        "samtools view -Sb - > {output}) 2> {log}"

    # -M is for compatibility with Picard later