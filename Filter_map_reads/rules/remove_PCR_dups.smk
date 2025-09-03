# Rule for removing PCR duplicates using Picard Tools
# Turns out you can just install Picard using conda so there is no need to faff about with Java and .jar filepaths

rule remove_dups:
    input:
        bam_in = "sorted_reads/{sample}.bam",
        bai = "sorted_reads/{sample}.bam.bai"
    output:
        bam_out = "BAM_files/{sample}.rmd.bam",
        stats = "BAM_files/remove_duplicates_stats/{sample}.rmd.bam.metrics"
    threads: 1
    conda:
        config["default_env"]
    log:
        "logs/remove_dups/{sample}.log"
    shell:
        "(picard MarkDuplicates REMOVE_DUPLICATES=true "
        "ASSUME_SORTED=true VALIDATION_STRINGENCY=SILENT MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=1000 INPUT={input.bam_in} "
        "OUTPUT={output.bam_out} METRICS_FILE={output.stats}) 2> {log}"