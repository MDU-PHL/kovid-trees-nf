include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process GOALIGN_DEDUP {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::goalign=0.3.2" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/goalign:0.3.2--h375a9b1_0"
    } else {
        container "quay.io/biocontainers/goalign:0.3.2--h375a9b1_0"
    }

    input:
    tuple val(meta), path(aln)

    output:
    tuple val(meta), path("*_dedup.aln"), emit: aln
    tuple val(meta), path("*.dedup"), emit: dedup
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    """
    goalign \\
        --auto-detect \\
        dedup \\
        $options.args \\
        -l ${prefix}.dedup \\
        -t $task.cpus \\
        -o ${prefix}_dedup.aln \\
        -i $aln

    echo \$(goalign version 2>&1) > ${software}.version.txt
    """
}
