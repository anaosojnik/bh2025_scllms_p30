nextflow.enable.dsl = 2

include { parseAsCmdArgs } from '../../modules/utils.nf'

// params.input_dir  = "./data"
// params.output_dir = "./results"
// params.threshold  = 0.05

// Channel
//     .fromPath("${params.input_dir}/*.csv")
//     .set { input_files }


process EMBED {
    input:
    val cliArgs

    output:
    path("${params.workflow.output_h5ad}"), emit: embeddings
    path("${params.workflow.umap_png ?: ''}"), optional: true, emit: umap

    // Convert map to CLI arguments
    // def cliArgs = config.collect { k, v -> "--${k} ${v}" }.join(' ')

    script:
    """
    python ${params.scriptsDir}/embed_and_umap.py ${cliArgs}
    """

    stub:
    """
    pwd
    #echo ${launchDir}
    #echo ${projectDir}
    #echo ${moduleDir}
    #export PYTHONPATH=\$PWD/bin:\$PYTHONPATH
    #echo \$PATH
    #export PATH=${projectDir}/bin:\$PATH
    ls ${projectDir}/bin
    echo \$PYTHONPATH
    python -c 'import sys; print(sys.path)'
    #python ${projectDir}/bin/${params.model}/test.py
    echo 'test' > ${params.workflow.output_h5ad}
    #echo 'test' > ${params.workflow.umap_png}
    #python ${projectDir}/bin/${params.model}/test.py --output results.csv --params ${moduleDir}/config.yaml    
    """
}

workflow CANCERF {

    main:
    // Import parameters
    // def configFile = "${moduleDir}/config.yaml"
    // def config = new groovy.yaml.YamlSlurper().parse(new File(configFile))

    // println("Workflow parameters loaded from file:")
    // println(config)

    // Parse CLI arguments
    cliArgs = parseAsCmdArgs(params.workflowParams)
    println(cliArgs)

    // Run task
    if (params.task == "embed") {
        result = EMBED(cliArgs)
        results = result.embeddings.combine(result.umap.ifEmpty([null]))
    } else {
        error("Task not implemented")
    }

    emit:
    results = results
}
