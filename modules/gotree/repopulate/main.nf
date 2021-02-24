include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process GOTREE_REPOPULATE {
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
    tuple val(meta), path(id_groups)

    output:
    tuple val(meta), path("*_repopulate.nwk"), emit: tree
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    """
    gotree \\
        repopulate \\
        $options.args \\
        -t $task.cpus \\
        -g $id_groups \\
        -i $nwk \\
        -o ${prefix}_repopulate.nwk \\

    echo \$(goalign version 2>&1) > ${software}.version.txt
    """
}
