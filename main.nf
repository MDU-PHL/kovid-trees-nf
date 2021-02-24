// a fast tree building workflow
nextflow.enable.dsl=2
params.enable_conda = true
params.publish_dir_mode = 'link'
params.outdir = 'results'
params.input_aln = 'tests/data/aln/test_aln.aln'
params.input_id = 'test'
// clipkit params
params.mode = 'kpic-smart-gap'
params.clipkit_log = true
// raxml params
params.subst_model = false // use default GTR+G4
params.force = false // use default perf_threads
// nw_reroot params
params.outgroup = 'ref\\|NC_045512.2\\|'

include { GOALIGN_REPLACE } from './modules/goalign/replace/main.nf' addParams(options: [
    args: "-e -s '[^ACTGactg]' -n '-'"
])
include { GOALIGN_CLEAN_SEQS } from './modules/goalign/clean/seqs/main.nf' addParams(options: [
    args: "--cutoff 0.05"
])
include { CLIPKIT } from './modules/clipkit/main.nf' addParams([:])
include { GOALIGN_DEDUP } from './modules/goalign/dedup/main.nf' addParams([:])
include { GOALIGN_COMPRESS } from './modules/goalign/compress/main.nf' addParams([:])
include { FASTTREE } from './modules/fasttree/main.nf' addParams(options: [
    args: "-nosupport -fastest"
])
include { GOTREE_RESOLVE } from './modules/gotree/resolve/main.nf' addParams([:])
include { RAXMLNG_EVALUATE } from './modules/raxml-ng/evaluate/main.nf' addParams(options: [
    args: "--blmin 0.0000000001"
])
include {GOTREE_BRLEN_ROUND } from './modules/gotree/brlen/round/main.nf' addParams(options: [
    args: "-p 6"
    ])
include {GOTREE_COLLAPSE_LENGTH } from './modules/gotree/collapse/length/main.nf' addParams(options: [
    args: "-l 0"
    ])
include { GOTREE_REPOPULATE } from './modules/gotree/repopulate/main.nf' addParams([:])
include { NWUTILS_ORDER } from './modules/newick_utils/order/main.nf' addParams([:])
include { NWUTILS_REROOT } from './modules/newick_utils/reroot/main.nf' addParams([:])

def data = [[id: "${params.input_id}"], file("${baseDir}/${params.input_aln}", checkIfExists: true)]

/*
 * Parse software version numbers
 */
process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: params.publish_dir_mode,
        saveAs: { filename ->
                      if (filename.indexOf(".csv") > 0) filename
                      else null
                }

    output:
    file 'software_versions_mqc.yaml' into ch_software_versions_yaml
    file "software_versions.csv"

    script:
    // TODO nf-core: Get all tools to print their version number here
    """
    echo $workflow.manifest.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    fastqc --version > v_fastqc.txt
    multiqc --version > v_multiqc.txt
    scrape_software_versions.py &> software_versions_mqc.yaml
    """
}

workflow {
    GOALIGN_REPLACE(data)
    GOALIGN_CLEAN_SEQS(GOALIGN_REPLACE.out.aln)
    CLIPKIT(GOALIGN_CLEAN_SEQS.out.aln)
    GOALIGN_DEDUP(CLIPKIT.out.aln)
    GOALIGN_COMPRESS(GOALIGN_DEDUP.out.aln)
    FASTTREE(GOALIGN_COMPRESS.out.aln)
    GOTREE_RESOLVE(FASTTREE.out.tree)
    RAXMLNG_EVALUATE(GOTREE_RESOLVE.out.tree, GOALIGN_COMPRESS.out.aln, GOALIGN_COMPRESS.out.weights)
    GOTREE_BRLEN_ROUND(RAXMLNG_EVALUATE.out.tree)
    GOTREE_COLLAPSE_LENGTH(GOTREE_BRLEN_ROUND.out.tree)
    GOTREE_REPOPULATE(GOTREE_COLLAPSE_LENGTH.out.tree, GOALIGN_DEDUP.out.dedup)
    NWUTILS_ORDER(GOTREE_REPOPULATE.out.tree)
    NWUTILS_REROOT(NWUTILS_ORDER.out.tree)
}