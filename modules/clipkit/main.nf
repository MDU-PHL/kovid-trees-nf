include { initOptions; saveFiles; getSoftwareName } from './functions'
params.options = [:]
def options    = initOptions(params.options)

process CLIPKIT {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::clipkit=1.1.1" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/clipkit:1.1.1--py_0"
    } else {
        container "quay.io/biocontainers/clipkit:1.1.1--py_0"
    }

    input:
    tuple val(meta), path(aln)

    output:
    tuple val(meta), path("*_filtered.aln"), emit: aln
    tuple val(meta), path("*.log"), optional: true, emit: log
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def mode = params.mode ? "-m $params.mode" : "-m gappy"
    def log = params.clipkit_log ? "-l" : ""
    """
    clipkit \\
        $aln \\
        $options.args \\
        ${mode} \\
        ${log} \\
        -o ${prefix}_filtered.aln

    clipkit --version | sed 's/clipkit //g' > ${software}.version.txt
    """
}
