nextflow.enable.dsl = 2

// params.input_dir  = "./data"
// params.output_dir = "./results"
// params.threshold  = 0.05

// Channel
//     .fromPath("${params.input_dir}/*.csv")
//     .set { input_files }

process RUN_PYTHON_ANALYSIS {
    input:
    val cliArgs

    output:
    tuple path("${params.workflow.umap_png}"), path("${params.workflow.output_h5ad}")

    // Convert map to CLI arguments
    // def cliArgs = config.collect { k, v -> "--${k} ${v}" }.join(' ')

    script:
    """
    pwd
    echo ${launchDir}
    echo ${projectDir}
    echo ${moduleDir}
    #export PYTHONPATH=\$PWD/bin:\$PYTHONPATH
    echo \$PATH
    export PATH=${projectDir}/bin:\$PATH
    #python -c 'import sys; print(sys.path)'
    #echo 'test' > ${params.workflow.output_h5ad}
    #echo 'test' > ${params.workflow.umap_png}
    #python ${projectDir}/bin/${params.model}/test.py --output results.csv --params ${moduleDir}/config.yaml
    python ${params.scriptsDir}/embed_and_umap.py ${cliArgs} #\
    #--input ${params.workflow.input} \
    #--output_h5ad ${params.workflow.output_h5ad} \
    #--model_dir ${params.workflow.model_dir} \
    #--batch_key ${params.workflow.batch_key} \
    #--bio_key ${params.workflow.bio_key} \
    #--umap_png ${params.workflow.umap_png}
    """
}

workflow CANCERF {

    main:
    // Import parameters
    // def configFile = "${moduleDir}/config.yaml"
    // def config = new groovy.yaml.YamlSlurper().parse(new File(configFile))

    // println("Workflow parameters loaded from file:")
    // println(config)

    def cliArgs = params.workflow.collect { k, v -> "--${k} ${v}" }.join(' ')
    println(cliArgs)

    // Run workflow
    results = RUN_PYTHON_ANALYSIS(cliArgs)

    emit:
    results = results
}
