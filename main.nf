nextflow.enable.dsl = 2

params.scriptsDir = "${projectDir}/bin/${params.model}"
params.outputDir = params.outputDir ?: "${projectDir}/outputs/${params.model}"

include { CANCERF } from './workflows/cancerf/cancerf.nf'
include { SCGPT } from './workflows/scgpt/scgpt.nf'

workflow {

    main:

    // Check if output directory exists, otherwise error
    def outDir = new File(params.outputDir)
    if (!outDir.exists()) {
        error("Output directory does not exist: ${outDir}")
    }

    // Run workflow for the specific model
    if (params.model == "cancerf") {
        results = CANCERF()
    }
    if (params.model == "scgpt") {
        results = SCGPT()
    }

    // View results
    results.view { "${it}" }

    publish:
    results = results
}

output {
    results {
        path "${params.model}/${params.resultsSubdir}"
        index {
            path "${params.model}/${params.resultsIndexSubdir}/index.csv"
        }
    }
}
