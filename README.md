# bh2025_scllms_p30

> [!CAUTION]
> This repo is work in progress. Workflow pipelines have not yet been fully tested. Use with care.

> [!WARNING]
> #TODO This description needs to be revised

Monorepo layout for scGPT, Cancer Foundation, and Nextflow pipelines.

## Table of contents

- [Structure](#structure)
    - [Workflow structure](#workflow-structure)
        - [Entry workflow](#entry-workflow)
        - [Model workflows](#model-workflows)
        - [Workflow processes](#workflow-processes)
    - [File structure](#file-structure)
- [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Instructions for setup and test workflow](#instructions-for-setup-and-test-workflow)
- [Running supported workflows](#running-supported-workflows)
    - [Models, workflows and tasks](#models-workflow-types-and-tasks)
    - [Datasets](#datasets)
- [Running customised workflows](#running-customised-workflows)
    - [Custom workflow configuration](#custom-workflow-configuration)
    - [Custom dataset](#custom-dataset)
    - [Custom container](#custom-workflow-configuration)
    - [Container system other than Docker](#container-system-other-than-docker)
    - [Custom profiles](#custom-profiles)
- [Generating provenance and RO-Crate metadata files](#generating-provenance-and-ro-crate-metadata-files)


## Structure

### Workflow structure

According to Nextflow [documentation](https://docs.seqera.io/nextflow/workflow), Nextflow pipelines are designed as follows. They can have **one entry workflow**, which then calls other **named workflows** depending on the configuration parameters. Named workflows then call specific processes (i.e. `bash` scripts) in a particular order. The structure of our pipeline follows this design.

This workflow also avoids setting parameters inside any of the `.nf` files, and no `.yaml` files are used to set parameters. All configuration parameters are defined in `<config-name>.config` files, including any parameters that are inputs to the Python scripts. See [Custom workflow configuration](#custom-workflow-configuration) for more details. 

#### Entry workflow
Our entry workflow is in file `main.nf`. It executes the following:
1. Checks if required configuration parameters are provided, these are `model` and `workflow` (#TODO `dataset`?).

    These parameters must be provided to the workflow, for example 
    ```
    nextflow run . --model <model> --workflow <workflow>
    ```
    This is already taken care of if using `make` commands (see `Makefile`), but `MODEL` and `WORKFLOW` may also have to be provided to the `make run` command, if not running the default workflow, for example as below.
    ```
    make run MODEL=<model> WORKFLOW=<workflow>
    ```

2. Checks if the output directory, where outputs from the entry workflow are published, exists

    This directory is defined in `nextflow.config` with `outputDir` and `params.outputDir` parameters. Please see instructions [Custom workflow configuration](#custom-workflow-configuration-warning) in case you want to change the output directory.

3. Depending on the `model` parameter, the entry workflow calls a named workflow (or subworkflow) called after the `model`, e.g. `CANCERF` or `SCGPT` (see [Model workflows](#model-workflows)).

4. Processes paths of output files from model (named) workflows, i.e. flattens paths in nested lists and removes `null` paths.

5. Publishes to `outputDir`
    - all files at output paths, and
    - an index file `index.csv` that lists names of all output files.

In summary, the entry workflow does some basic workflow parameter checks, gets outputs as file paths, which it minimally processes, and at the end it publishes the files with a file index to the `outputDir`. This way all the named (sub)workflows do not have to be concerned about any of this; they must simply make sure then pass (`emit`) the outputs to the entry workflow in a format that can be correctly processed by the entry workflow. The expected format is a list of file paths of output files, or a list of lists of file paths.


#### Model workflows
Model (sub)workflows or named workflows call relevant processes for a specific model. We have **one named workflow per model**.

Model workflows can be found at `workflows/<model>/<model>.nf`. 

They execute the following:
1. Parse as a string the command line arguments needed for running the Python script.

    These arguments are in the `params.workflowParams` parameter and are defined in workflow-specific configuration files (see [Custom workflow configuration](#custom-workflow-configuration-warning)).

2. Depending on the `workflow` configuration parameter, run the specific workflow process (see [Workflow processes](#workflow-processes)) with the parsed CLI arguments as string input.

3. Cast output file paths from the process to the correct format for processing in the entry workflow (see `CANCERF` workflow in `workflows/cancerf/cancerf.nf` as example).

4. Emit output file paths, i.e. pass to the parent workflow script.


#### Workflow processes
At the moment, each workflow is run with a single Python script. Therefore, we define **one process per workflow type**. For example, workflow types are `embded` or `finetune`.

All processes are for now defined in the same file as the model workflow script from which they are called, this is in the `workflows/<model>/<model>.nf` file. Please see `EMBED` process in `workflows/cancerf/cancerf.nf` as an example of how processes should be written.

Processes are defined by the following 4 components:

- `input`: CLI arguments needed for the script, parsed as a string; 
    
    Other pre-computed values can potentially be passed as inputs, but note that since processes can access the workflow configuration parameters in `params`, this is generally not needed.

- `output`: paths of output files, can be defined as
    - paths of all generated files `path("*")`, output as a list, or
    - specific paths `path(${params.<specific-output-path>})` as in `EMBED`; in the case of specific paths, paths must be combined together (see `CANCERF`), or if some specifically-defined output files are optional, set `optional: true` in their definition (see `EMBED`)

- `script`: `bash` script to be run when the process is called

    This is where a relevant Python script to be executed is called. The script should be located at `bin/<model>` and called by its absolute path `${params.scriptsDir}/<script-name>.py` (see `EMBED`). The script is executed from `.work/<current-run-subdirectory>`, which gets randomly generated on workflow run.
    
    For Python to see all the relevant Python files, `bin/shared` and `external/<model>` get added to `PYTHONPATH` in `nextflow.config`. Any Python code in the parent directory of the executed Python script is seen by Python automatically.

- `stub`: test `bash` script that is run when `-stub-run` is passed to `nextflow run`

    In this case, `stub` script is run instead of the `script` to test if the workflow theoretically runs with given inputs and outputs. It is recommended that `stub` creates fake output files if outputs are required for the Nextflow workflow not to fail.


### File structure

> [!NOTE]
> `pipelines` directory still exists, but is deprecated in this version. The majority of relevant files have been moved from the `pipelines` directory into the new structure.

- `Makefile`: contains commands for setup, running the workflow and cleaning up
- `main.nf`: **main (entry) workflow script**, which calls subworkflows, i.e. for each model there is a separate subworkflow script that gets called
- `nextflow.config`: **main Nextflow configuration file**, defines key input parameters and directory structure
- `workflows`: Nextflow **subworkflows**, split by model
- `configs`: Nextflow additional configuration files split by model and by workflow type
- `modules`: shared Groovy/Nextflow code, used by all workflows and subworkflows, e.g. `modules/utils.nf`
- `bin`: **all our Python code**, split by model or according to whether the code is shared between all models
    - `shared`: folder added to PYTHONPATH for all models
    - `cancerf`: folder added to PYTHONPATH only for cancerfoundation
    - `scgpt`: folder added to PYTHONPATH only for scgpt
- `external`: all external dependencies, e.g. external Python code
    - `scgpt`: original scGPT repo as a git submodule
    - `cancerf`: original Cancer Foundation repo as a git submodule
- `assets`: any extra files that may be used by models, e.g. model weight files (see the file download section of the `Makefile`)
- `containers`: files that specify container environments, i.e. Dockerfiles, split by model into subdirectories; `docker-compose.yml` contains instructions for building and running the different containers, but one can also build them with `make build <...args>` (see `Makefile`)
- `data`: directory with all **experimental datasets**, every dataset should be in its own subfolder
- `outputs`: directory where **results** are published according to the current configuration in `nextflow.config`; results are split by model in subdirectories
- `.work`: Nextflow working directory with all run working files and outputs before some files are pub  lished to `outputs`
- `.venv` (optional): Python virtual environment with `gdown` package, only needed if executing automatic data downloads


## Setup

### Prerequisites
- Docker
- Nextflow (version 25.10.4)
- Python
- gdown (Python package) in an actived Python virtual environment (`Makefile` assumes the virtual environment is at `.venv`)


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
6. Run test workflow for a specific model and workflow type.
    ```
    make run MODEL=<model> WORKFLOW=<workflow> GPU=<true if gpu needed, otherwise delete this argument>
    ```

## Running supported workflows
### Models, workflow types and tasks

> [!WARNING]
> This is #TODO

This repo supports running the following models, workflow types and tasks:
| Model | Workflow types | Tasks |
| --- | ----------- | ----- |
| [CancerFoundation](#cancerf) | embed<br> | task1 |
| [scGPT](#scgpt) | embed<br>finetune | task1<br>task2 |

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
- `configs/<model>/<workflow>.config`: workflow-type-specific configuration.
> #TODO We probably also need task-specific configuration. To think about and implement

By definition in this repo, the types of parameters in each of these files are disjoint, i.e. do not overlap. However, it is worth noting that generally model-specific configuration overrides the core configuration, while workflow-specific configuration overrides the other two.

You can also add your own configuration file in the `nextflow -c configs/<my-config>.config run .` command, which overrides all of the other configurations.

File `nextflow.config` is heavily commented and provides further instructions on how to change certain workflow configuration parameters.

<span id="custom-workflow-configuration-warning"></span>

> [!WARNING]
> When changing the directory `outputDir`, where workflow outputs are published, make sure you do not change it via the `nextflow run . -output-dir` in command line. Change it instead in `nextflow.config` by defining both variables `outputDir` and `params.outputDir` as instructed in the comments in this file. If these folders are defined after the `with_prov` profile is defined, then generation of provenance files may not work correctly.


### Custom dataset

> [!WARNING]
> This is #TODO

### Custom container
1. Create your Dockerfile in the appropriate subfolder in `container` folder.

2. Build your custom container as follows.
    ```
    docker build -t <image-name>:latest -f <path/to/your/custom/Dockerfile> 
    ```

3. Edit variable `process.container` in `nextflow.config`, or add to your custom configuration file `configs/<my-config>.config` and include your custom configuration file in your run (see [Custom workflow configuration](#custom-workflow-configuration)).

4. Run your workflow as usual.
    ```
    nextflow run . --model <model> --workflow <workflow> --gpu <true/false> -profile <profiles-comma-separated>
    ```

### Container system other than Docker
By default, workflows are run in Docker. If Docker is not available on your machine, Nextflow also supports Apptainer.

> [!CAUTION]
> Running the workflows with Apptainer has not yet been tested.


### Custom profiles

> [!WARNING]
> #TODO Add description of profiles



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


