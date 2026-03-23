nextflow.enable.dsl = 2

// params.input_dir  = "./data"
// params.output_dir = "./results"
// params.threshold  = 0.05

// Channel
//     .fromPath("${params.input_dir}/*.csv")
//     .set { input_files }

process RUN_PYTHON_ANALYSIS {
    input:
    val config

    output:
    tuple path("${config.umap_png}"), path("${config.output_h5ad}")

    script:
    """
    pwd
    echo ${launchDir}
    echo ${projectDir}
    echo ${moduleDir}
    python ${projectDir}/bin/test.py --output results.csv --params ${moduleDir}/config.yaml
    """
}

workflow SCGPT {

    main:
    // Import parameters
    def configFile = "${moduleDir}/config.yaml"
    def config = new groovy.yaml.YamlSlurper().parse(new File(configFile))

    // println("Workflow parameters loaded from file:")
    // println(config)

    // Run workflow
    results = RUN_PYTHON_ANALYSIS(config)

    emit:
    results = results
}
