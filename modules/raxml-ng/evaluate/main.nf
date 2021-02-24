include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process RAXMLNG_EVALUATE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::raxml-ng=1.0.1" : null)

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/raxml-ng:1.0.1--h7447c1b_0"
    } else {
        container "quay.io/biocontainers/raxml-ng:1.0.1--h7447c1b_0"
    }

    input:
    tuple val(meta), path(nwk)
    tuple val(meta), path(aln)
    tuple val(meta), path(weights)

    output:
    tuple val(meta), path("*.raxml.bestTree"), emit: tree
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    // required to ensure it doesn't exit out with issues with threading
    def force    = params.force ? "${params.force}" : "--force perf_threads"
    // required to run evalute
    def model    = params.subst_model ? "--model ${params.subst_model}" : "--model GTR+G4"
    """
    raxml-ng \\
    --evaluate \\
    $options.args \\
    --threads $task.cpus \\
    --prefix ${prefix} \\
    $force \\
    $model \\
    --tree $nwk \\
    --msa $aln \\
    --site-weights $weights

    raxml-ng --version | grep release | sed -e 's/^.*v. //g' -e 's/ released.*\$//g' > ${software}.version.txt
    """
}
