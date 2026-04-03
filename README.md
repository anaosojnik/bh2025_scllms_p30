# bh2025_scllms_p30

> [!WARNING]
> #TODO This description needs to be revised

Monorepo layout for scGPT, Cancer Foundation, and Nextflow pipelines.

## Table of contents

- [Structure](#structure)
- [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Instructions for setup and test workflow](#instructions-for-setup-and-test-workflow)
- [Running supported workflows](#running-supported-workflows)
    - [Models and tasks](#models-and-tasks)
- [Running customised workflows](#running-customised-workflows)
    - [Custom workflow configuration](#custom-workflow-configuration)
    - [Custom dataset](#custom-dataset)
    - [Custom container](#custom-workflow-configuration)
- [Generating provenance and RO-Crate metadata files](#generating-provenance-and-ro-crate-metadata-files)

## Structure

- `Makefile`: contains commands for setup, running the workflow and cleaning up
- `main.nf`: **core workflow script**, which calls subworkflows, i.e. for each model there is a separate subworkflow script that gets called
- `nextflow.config`: **core Nextflow configuration file**, defines key input parameters and directory structure
- `workflows`: Nextflow **subworkflows**, split by model
- `configs`: Nextflow additional configuration files split by model and by task
- `modules`: shared Groovy/Nextflow code, used by all workflows and subworkflows
- `bin`: **all our Python code**, split by model or according to whether the code is shared between all models
    - `shared`: folder added to PYTHONPATH for all models
    - `cancerf`: folder added to PYTHONPATH only for cancerfoundation
    - `scgpt`: folder added to PYTHONPATH only for scgpt
- `external`: all external dependencies, e.g. external Python code
    - `scgpt`: original scGPT repo as a git submodule
    - `cancerf`: original Cancer Foundation repo as a git submodule
- `assets`: any extra files that may be used by models, e.g. model weight files (see the file download section of the `Makefile`)
- `containers`: files that specify container environments, i.e. Dockerfiles, split by model into subdirectories; `docker-compose.yml` contains instructions for building and running the different containers, but one can also build them with `make build <...args>` (see `Makefile`)
- `outputs`: directory where **results** are published according to the current configuration in `nextflow.config`; results are split by model in subdirectories
- `.work`: Nextflow working directory with all run working files and outputs before some files are published to `outputs`

## Setup

### Prerequisites
- Docker
- Nextflow (version 25.10.4)
- Python
- gdown (Python package) in an actived Python virtual environment


### Instructions for setup and test workflow
1. Clone this repo.
2. Clone all submodules in the repo.
    ```
    git submodule update --init --recursive
    ```
3. Activate a Python virtual environment with `gdown` installed.
4. Check that you have all the prerequisites installed.
    ```
    make prereq
    ```
5. Build containers needed for running a specific model.
    ```
    make build MODEL=<model> GPU=<true if gpu needed, otherwise delete this argument>
    ```
6. Run test workflow for a specific model and task.
    ```
    make run MODEL=<model> TASK=<task> GPU=<true if gpu needed, otherwise delete this argument>
    ```

## Running supported workflows
### Models and tasks

> [!WARNING]
> This is #TODO

This repo supports running the following models and tasks:
| Model | Tasks |
| --- | ----------- |
| [CancerFoundation](#cancerf) | task1 |
| [scGPT](#scgpt) | task1<br>task2 |

#### References

- <span id="cancerf"></span>CancerFoundation
    > #TODO add reference

- <span id="scgpt"></span>scGPT
    > #TODO add reference


### Datasets

> [!WARNING]
> This is #TODO

## Running customised workflows

If you want to run your a customised workflow, we recommend not using the `make` commands, but running your own commands directly.

### Custom workflow configuration
To customise your workflow configuration, there are three types of configuration files you can edit:
- `nextflow.config`: core configuration,
- `workflows/<model>/<model>.config`: model-specific configuration, and
- `configs/<model>/<task>.config`: task-specific configuration.

By definition in this repo, the types of parameters in each of these files are disjoint, i.e. do not overlap. However, it is worth noting that generally model-specific configuration overrides the core configuration, while task-specific configuration overrides the other two.

You can also add your own configuration file in the `nextflow -c configs/<my-config>.config run .` command, which overrides all of the other configurations.

File `nextflow.config` is heavily commented and provides further instructions on how to change certain workflow configuration parameters.

> [!WARNING]
> When changing the directory `outputDir`, where workflow outputs are published, make sure you do not change it via the `nextflow run . -output-dir` in command line. Change it instead in `nextflow.config` by defining both variables `outputDir` and `params.outputDir` as instructed in the comments in the config file. If these folders are defined after the `with_prov` profile is defined, then provenance may not work correctly.


<!-- ### Custom dataset -->


### Custom container
1. Create your Dockerfile in the appropriate subfolder in `container` folder.
2. Build your custom container as follows.
    ```
    docker build -t <image-name>:latest -f <path/to/your/custom/Dockerfile> 
    ```
3. Edit variable `process.container` in `nextflow.config`, or add to your custom configuration file `configs/<my-config>.config` and include your custom configuration file in your run (see [Custom workflow configuration](#custom-workflow-configuration)).
4. Run your workflow as usual.
    ```
    nextflow run . --model <model> --task <task> --gpu <true/false> -profile <profiles-comma-separated>
    ```




<!-- ```bash
cd pipelines
nextflow run . -main-script ./workflows/scgpt_fine_tuning_cell_types_workflow.nf
```

Alternatively you could use the makefile for some common scenarios.

```bash
make scgpt
``` -->

<!-- ## Customising Docker images

You might need to specify the name of the docker image you use using the nextflow config parameter _container_image_, which you can specify in a config file such as `~/.nextflow/config`. This file is read automatically so there is no need to change the commandlines. -->


## Generating provenance and RO-Crate metadata files

> [!WARNING]
> This is outdated. #TODO

### nf-prov plugin for Nextflow
`nf-prov` is a Nexflow plugin that automatically generates Workflow **Run** RO-Crate (WRROC), this here means it automatically generates the `ro-crate-metadata.json` file in the standard [WRROC format](https://www.researchobject.org/workflow-run-crate/).

You can run it with

```bash
make scgpt-test
```

nf-prov only generates a WRROC for a particular run, and not a [Workflow RO-Crate](https://about.workflowhub.eu/Workflow-RO-Crate/). The latter is the final one we need to publish on WorkflowHub, so we need to do some editing/merging.


