nextflow.enable.dsl = 2

include { CANCERF } from './workflows/cancerf/cancerf.nf'
include { SCGPT } from './workflows/scgpt/scgpt.nf'

workflow {

    main:

    // Check if model and task defined
    if( !params.model ) {
        error("Parameter --model is required. Re-run workflow with a model-specific profile.")
    }
    if( !params.task ) {
        error("Parameter --task is required. Re-run workflow by adding a task parameter.")
    }

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

    // Flatten results and
    // remove optional results, which output as null
    results = results.flatten().filter { it != null } 

    println("results:")
    results.view { "${it}" }

    publish:
    results = results
}

// Define how results are published
output {
    results {
        path "${params.resultsSubdir}"
        index {
            path "${params.resultsIndexSubdir}/index.csv"
        }
    }
}
