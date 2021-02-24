include { initOptions; saveFiles; getSoftwareName } from './functions'
params.options = [:]
def options    = initOptions(params.options)

process FASTTREE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::fasttree=2.1.10" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/fasttree:2.1.10--h516909a_4"
    } else {
        container "quay.io/biocontainers/fasttree:2.1.10--h516909a_4"
    }

    input:
    tuple val(meta), path(aln)

    output:
    tuple val(meta), path("*.nwk"), emit: tree
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"

    """
    OMP_NUM_THREADS=$task.cpus \\
        fasttree \\
        $options.args \\
        -out ${prefix}.nwk \\
        -nt $aln

    (fasttree 2>&1) | grep version | sed -e 's/.*version //g' -e 's/ Double.*\$//g' > ${software}.version.txt
    """
}
