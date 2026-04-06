nextflow.enable.dsl = 2

include { parseAsCmdArgs } from '../../modules/utils.nf'

// params.input_dir  = "./data"
// params.output_dir = "./results"
// params.threshold  = 0.05

// Channel
//     .fromPath("${params.input_dir}/*.csv")
//     .set { input_files }

process INFERENCE {
    input:
    val cliArgs

    output:
    path "*"

    script:
    """
    python ${params.scriptsDir}/inference_cell_types.py ${cliArgs}
    """

    stub:
    """
    echo 'test' > out.txt
    """
}

process FINETUNE {
    input:
    val cliArgs

    output:
    path "*"

    script:
    """
    python ${params.scriptsDir}/fine_tuning_cell_types.py ${cliArgs}
    """

    stub:
    """
    echo 'test' > out.txt
    """
}

process FINETUNE_INTEGRATION {
    input:
    val cliArgs

    output:
    path "*"

    script:
    """
    export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:32"
    python ${params.scriptsDir}/finetune_integration_nextflow_core.py ${cliArgs}
    """

    stub:
    """
    echo 'test' > out.txt
    """
}

workflow SCGPT {

    main:
    // Run workflow
    scriptArgs = parseAsCmdArgs(params.workflowParams.script)
    println(scriptArgs)

    if (params.task == "inference") {
        results = INFERENCE(scriptArgs)
    }
    else if (params.task == "finetune") {
        results = FINETUNE(scriptArgs)
    }
    else if (params.task == "finetune_integration") {
        results = FINETUNE_INTEGRATION(scriptArgs)
    } else {
        error("Task not implemented")
    }

    emit:
    results = results
}
