nextflow.enable.dsl = 2

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
    else if (params.model == "scgpt") {
        results = SCGPT()
    }

    // View results

    // results.flatten().view { v -> "${v}  (${v?.getClass()})" }

    results = results.flatten().filter { it != null }

    println("results:")
    results.view { "${it}" }

    publish:
    results = results
}

output {
    results {
        path "${params.resultsSubdir}"
        index {
            path "${params.resultsIndexSubdir}/index.csv"
        }
    }
}
