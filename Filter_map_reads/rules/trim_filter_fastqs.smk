# Snakemake rule that uses fastp to trim and filter paired-end read fastqs

rule trim_filter_fastqs:
    input:
        f = lambda wildcards: config["forward"][wildcards.sample], 
        r = lambda wildcards: config["reverse"][wildcards.sample]
    output:
        f = temp("trimmed_reads/{sample}.fastp.1.fq.gz"), # temp because they take up space and aren't our target
        r = temp("trimmed_reads/{sample}.fastp.2.fq.gz"),
        html = "trim_fastq_reports/{sample}.fastp.html" # We will hold on to these since they are small and we might want to look at them later
    conda:
        config["default_env"]
    log:
        "logs/trim_filter_fastqs/{sample}.log"
    shell:
        "(fastp --thread {threads} --in1 {input.f} --in2 {input.r} --out1 {output.f} --out2 {output.r} -l 50 -h {output.html}) 2> {log}"