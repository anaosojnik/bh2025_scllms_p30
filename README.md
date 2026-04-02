# bh2025_scllms_p30

Monorepo layout for scGPT, Cancer Foundation, and Nextflow pipelines.

## Structure [in progress]

- `main.nf`: core workflow script, which calls subworkflows, i.e. for each model there is a separate subworkflow script that gets called
- `nextflow.config`: core Nextflow config, defines key input parameters and directory structure
- `workflows`: Nextflow subworkflows split by model
- `configs`: Nextflow configs split by model and by task
- `modules`: shared groovy/Nextflow code, used by all workflows and subworkflows
- `bin`: all Python code, split by model or whether is it shared between all models
    - `shared`: added to PYTHONPATH for all models
    - `cancerf`: added to PYTHONPATH only for cancerfoundation
    - `scgpt`: added to PYTHONPATH only for scgpt
- `outputs`: 
- `external`: all external dependencies
    - `scgpt`: original scGPT as a git submodule
    - `cancerf`: original Cancer Foundation as a git submodule

## Setup

- Use gh to fork upstream repos and clone this repo, then add submodules under external/

### prerequisite

- docker
- nextflow
- gdown python package

## usage

```bash
cd pipelines
nextflow run . -main-script ./workflows/scgpt_fine_tuning_cell_types_workflow.nf
```

Alternatively you could use the makefile for some common scenarios.

```bash
make scgpt
```

### customising the docker image

You might need to specify the name of the docker image you use using the nextflow config parameter _container_image_, which you can specify in a config file such as `~/.nextflow/config`. This file is read automatically so there is no need to change the commandlines.


## RO-Crates

### nf-prov plugin for Nextflow
`nf-prov` is a Nexflow plugin that automatically generates Workflow **Run** RO-Crate (WRROC), this here means it automatically generates the `ro-crate-metadata.json` file in the standard [WRROC format](https://www.researchobject.org/workflow-run-crate/).

You can run it with

```bash
make scgpt-test
```

nf-prov only generates a WRROC for a particular run, and not a [Workflow RO-Crate](https://about.workflowhub.eu/Workflow-RO-Crate/). The latter is the final one we need to publish on WorkflowHub, so we need to do some editing/merging.


