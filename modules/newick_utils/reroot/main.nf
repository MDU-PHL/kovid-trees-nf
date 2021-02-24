include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process NWUTILS_REROOT {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::newick_utils=1.6" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/newick_utils:1.6--h516909a_3"
    } else {
        container "quay.io/biocontainers/newick_utils:1.6--h516909a_3"
    }

    input:
    tuple val(meta), path(nwk)

    output:
    tuple val(meta), path("*_reroot.nwk"), emit: tree
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def outgroup = params.outgroup
    """
    nw_reroot \\
        $nwk \\
        $outgroup > ${prefix}_reroot.nwk

    echo "1.6" > ${software}.version.txt
    """
}
