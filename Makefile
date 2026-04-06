.PHONY: help #prereq run clean test clean-old image scgpt cancerf cancerf-cpu cancerf-cpu-test

# Default parameters (can be overridden)
# Run parameters
MODEL := cancerf ## which model to run
WORKFLOW := embed ## which task to run
GPU := ## whether to run with gpu - true or empty (=false)
GPU_BOOL := $(if $(GPU),$(GPU),false)
PROV := ## whether to run with provenance - empty (=false) or true
NXF_PROFILE := $(if $(PROV),"-profile with_prov","")

# Build parameters
MODEL_SUFFIX := $(if $(GPU),,-cpu)
IMAGE_TAG := $(MODEL)$(MODEL_SUFFIX):latest
DOCKERFILE := containers/$(MODEL)/$(MODEL)$(MODEL_SUFFIX).Dockerfile

# File parameters
DATASET = test ## which dataset to run
DATA_DIR = data/$(DATASET)
MODEL_DIR = assets/$(MODEL)


#TODO revise
help: ## Show this help message
	@echo "Nextflow Pipeline Makefile"
	@echo ""
	@echo "Usage:"
# 	@echo "  make setup               - Installs gdown in .venv virtual environment"
	@echo "  make prereq              - Checks the requirements"
	@echo "  make image               - Build the Docker image"
	@echo "  make test                - Run test pipeline with any parameters (-stub-run)"
	@echo "  make run                 - Run with own parameters (must be defined, see example below), includes data download"
	@echo "  make scgpt               - Run scgpt finetuning with default configuration, includes data download"
	@echo "  make cancerf             - Run cancerf embedding with default configuration, includes data download"
	@echo "  make clean               - Clean work/metadata of all runs"
	@echo "  make clean-old           - Clean work/metadata of runs older than the latest nextflow run"
	@echo ""
	@echo "Parameters (can be overridden):"
	@echo "  MODEL=$(MODEL)"
	@echo "  WORKFLOW=$(WORKFLOW)"
	@echo "  GPU=$(GPU)"
	@echo "  PROV=$(PROV)"
	@echo "  DATASET=$(DATASET)"
	@echo ""
	@echo "Examples:"
	@echo "  make run MODEL=cancerf WORKFLOW=embed GPU=true"

### SETUP
# Verify the prerequisites
prereq: 
	@docker version
	@nextflow info
 	@pip show gdown
	@echo "prerequisites installed"

# Activate virtual environment and install prerequisites
# Virtual environment is assumed to be in .venv folder in the repo
setup: 
	@source .venv/bin/activate && pip install gdown


### DATA & MODEL DOWNLOAD
ifeq ($(MODEL),scgpt)
	MODEL_FILES := \
		$(MODEL_DIR)/scgpt/best_model.pt \
		$(MODEL_DIR)/scgpt/vocab.json \
		$(MODEL_DIR)/scgpt/args.json
	DATA_FILES := \
		$(DATA_DIR)/c_data.h5ad \
		$(DATA_DIR)/filtered_ms_adata.h5ad
else ifeq ($(MODEL),cancerf)
	MODEL_FILES := external/cancerf/model/assets/model.pt
	DATA_FILES := $(DATA_DIR)/neftel_ss2.h5ad
endif

# Data files - make will skip if they exist
# scgpt test data
$(DATA_DIR)/c_data.h5ad:
	@echo "Download not yet implemented"
# 	@echo "Downloading c_data.h5ad"
# 	@mkdir -p $(DATA_DIR)
# 	@python3 -m gdown 1bV1SHKVZgkcL-RmmuN51_IIUJTSJbXOi --quiet -O $@

$(DATA_DIR)/filtered_ms_adata.h5ad:
	@echo "Download not yet implemented"
# 	@echo "Downloading filtered_ms_adata.h5ad"
# 	@mkdir -p $(DATA_DIR)
# 	@python3 -m gdown 1casFhq4InuBNhJLMnGebzkRXM2UTTeQG --quiet -O $@

# cancerf test data
$(DATA_DIR)/neftel_ss2.h5ad:
	@echo "Download not yet implemented"
#TODO

# Model files - make will skip if they exist
# scgpt
$(MODEL_DIR)/scgpt/best_model.pt:
	@echo "Download not yet implemented"
# 	@echo "Downloading best_model.pt"
# 	@mkdir -p $(MODEL_DIR)
# 	@python3 -m gdown 1PsOOAXioZ7twJZiIhvxg5c5HD18fAtYt --quiet -O $@

$(MODEL_DIR)/scgpt/vocab.json:
	@echo "Download not yet implemented"
# 	@echo "Downloading vocab.json"
# 	@mkdir -p $(MODEL_DIR)
# 	@python3 -m gdown 10D8_BtS3PORqawUwjWh5Dm_blDfRhm3r --quiet -O $@

$(MODEL_DIR)/scgpt/args.json:
	@echo "Download not yet implemented"
# 	@echo "Downloading args.json"
# 	@mkdir -p $(MODEL_DIR)
# 	@python3 -m gdown 1GTQXIwa4yzbRZlarGgHkmC9k8hD6x1hA --quiet -O $@

# cancerf
external/cancerf/assets/model/best_model.pt:
	@echo "Download not yet implemented"
# 	@echo "Downloading model.pt"
# 	@mkdir -p external/cancerf/assets/model
#TODO 	@python3 -m gdown 1PsOOAXioZ7twJZiIhvxg5c5HD18fAtYt --quiet -O $@

# Convenience targets that depend on the files
download-data: $(DATA_FILES) ## Download the data

download-model: $(MODEL_FILES) ## Download the model


### BUILD
image: $(DOCKERFILE) ## Build the Docker image
	@docker build -t $(IMAGE_TAG) -f $(DOCKERFILE)


### RUN
# full pipelines
run: download-data download-model ## Run Nextflow pipeline with any parameters
	@nextflow run . --model $(MODEL) --task $(WORKFLOW) --gpu $(GPU_BOOL) $(NXF_PROFILE)

scgpt: ## download data and run scgpt finetuning on GPU
	$(MAKE) run MODEL=scgpt WORKFLOW=finetune GPU=true

cancerf: ## download data and run cancerf embedding on GPU
	$(MAKE) run MODEL=cancerf WORKFLOW=embed GPU=true

# test pipelines (-stub-run)
test: ## Run Nextflow test pipeline with any parameters (i.e. Nextflow stub run)
	@nextflow run . --model $(MODEL) --task $(WORKFLOW) --gpu $(GPU_BOOL) $(NXF_PROFILE) -stub-run

cancerf-cpu-test: #download-data download-model ## Run the cancerf test pipeline
	@nextflow run . --model cancerf --task embed --gpu false $(NXF_PROFILE) -stub-run


### MAINTENANCE
clean: ## Clean Nextflow work directories and results
	rm -rf outputs
	rm -rf results
	rm -rf reports
	rm -rf .nextflow*
	nextflow clean -f

clean-old: ## Clean work/metadata of runs older than the latest
	@RUN_ID=$$(nextflow log -q | tail -1); \
	if [ -n "$$RUN_ID" ]; then \
	  echo "Cleaning runs before: $$RUN_ID"; \
	  nextflow clean -f -before $$RUN_ID; \
	else \
	  echo "No Nextflow runs found"; \
	fi