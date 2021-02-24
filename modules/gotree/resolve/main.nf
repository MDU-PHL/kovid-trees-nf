include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process GOTREE_RESOLVE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::gotree=0.4.0" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gotree:0.4.0--h375a9b1_0"
    } else {
        container "quay.io/biocontainers/gotree:0.4.0--h375a9b1_0"
    }

    input:
    tuple val(meta), path(nwk)

    output:
    tuple val(meta), path("*_resolve.nwk"), emit: tree
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    """
    gotree \\
        resolve \\
        $options.args \\
        -t $task.cpus \\
        -i $nwk \\
        -o ${prefix}_resolve.nwk \\

    echo \$(goalign version 2>&1) > ${software}.version.txt
    """
}
