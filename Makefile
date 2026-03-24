.PHONY: help prereq run clean test clean-old image scgpt cancerf cancerf-cpu cancerf-cpu-test

# Default parameters (can be overridden)
# Run parameters
MODEL := cancerf
CPU := ## true or empty
MODEL_SUFFIX := $(if $(CPU),-cpu,)
IMAGE_TAG := $(MODEL)$(MODEL_SUFFIX):latest
DOCKERFILE := containers/$(MODEL)/$(MODEL)$(MODEL_SUFFIX).Dockerfile
PROV := ## empty or true
NXF_PROFILE := $(if $(PROV),"with_prov","")$(MODEL)$(if $(CPU),_cpu,)
TASK := inference

# File parameters
DATASET = test
DATA_DIR = data/$(DATASET)
MODEL_DIR = assets/$(MODEL)

help: ## Show this help message
	@echo "Nextflow Pipeline Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make scgpt               - Run the scgpt pipeline with default parameters"
	@echo "  make prereq              - Install the requirements"
	@echo "  make image               - Build the Docker image"
	@echo "  make clean               - Clean Nextflow work directories and results"
	@echo "  make clean-old           - Clean work/metadata of runs older than the latest nextflow run"
	@echo "  make test                - Run with test parameters"
	@echo ""
	@echo "Parameters (can be overridden):"
	@echo "  INPUT_VALUE=$(INPUT_VALUE)"
	@echo "  PROCESSING_MODE=$(PROCESSING_MODE)"
	@echo ""
	@echo "Examples:"
	@echo "  make run MODEL=cancerf CPU=true PROV=true PROCESSING_MODE=debug"
	@echo "  make test"

prereq: ## verify the prerequisites
	@docker version
	@nextflow info
 	@pip show gdown
	@echo "prerequisites installed"

setup: ## install prerequisites
	@pip install gdown


### DATA & MODEL DOWNLOAD
ifeq ($(MODEL),scgpt)
	MODEL_FILES := \
		$(MODEL_DIR)/scgpt/best_model.pt \
		$(MODEL_DIR)/scgpt/vocab.json \
		$(MODEL_DIR)/scgpt/args.jsonelse
	DATA_FILES := \
		$(DATA_DIR)/c_data.h5ad \
		$(DATA_DIR)/filtered_ms_adata.h5ad
else ifeq ($(MODEL),cancerf)
	MODEL_FILES := external/cancerf/model/assets/model.pt
	DATA_FILES := $(DATA_DIR)/neftel_ss2.h5ad
endif

# Data files - make will skip if they exist
$(DATA_DIR)/c_data.h5ad:
	@echo "Downloading c_data.h5ad"
	@mkdir -p $(DATA_DIR)
	@python3 -m gdown 1bV1SHKVZgkcL-RmmuN51_IIUJTSJbXOi --quiet -O $@

$(DATA_DIR)/filtered_ms_adata.h5ad:
	@echo "Downloading filtered_ms_adata.h5ad"
	@mkdir -p $(DATA_DIR)
	@python3 -m gdown 1casFhq4InuBNhJLMnGebzkRXM2UTTeQG --quiet -O $@

# Model files - make will skip if they exist
$(MODEL_DIR)/scgpt/best_model.pt:
	@echo "Downloading best_model.pt"
	@mkdir -p $(MODEL_DIR)
	@python3 -m gdown 1PsOOAXioZ7twJZiIhvxg5c5HD18fAtYt --quiet -O $@

$(MODEL_DIR)/scgpt/vocab.json:
	@echo "Downloading vocab.json"
	@mkdir -p $(MODEL_DIR)
	@python3 -m gdown 10D8_BtS3PORqawUwjWh5Dm_blDfRhm3r --quiet -O $@

$(MODEL_DIR)/scgpt/args.json:
	@echo "Downloading args.json"
	@mkdir -p $(MODEL_DIR)
	@python3 -m gdown 1GTQXIwa4yzbRZlarGgHkmC9k8hD6x1hA --quiet -O $@


external/cancerf/assets/model/best_model.pt:
	@echo "Downloading model.pt"
	@mkdir -p external/cancerf/assets/model
# 	@python3 -m gdown 1PsOOAXioZ7twJZiIhvxg5c5HD18fAtYt --quiet -O $@

# Convenience targets that depend on the files
download-data: $(DATA_FILES) ## Download the data

download-model: $(MODEL_FILES) ## Download the model


### BUILD
image: $(DOCKERFILE) ## Build the Docker image
	@docker build -t $(IMAGE_TAG) -f $(DOCKERFILE)


### RUN
run: download-data download-model ## Run the Nextflow pipeline
	@nextflow run . -profile $(NXF_PROFILE) --task $(TASK)

# scgpt: download-data download-model ## Run the Nextflow pipeline
# 	@nextflow run . -profile scgpt

# cancerf: download-data download-model ## Run the Nextflow pipeline
# 	@nextflow run . -profile cancerf

# cancerf-cpu: download-data download-model ## Run the Nextflow pipeline
# 	@nextflow run . -profile cancerf_cpu

cancerf-cpu-test: #download-data download-model ## Run the Nextflow pipeline
	@nextflow run . -profile cancerf_cpu --task $(TASK) -stub-run

test: ## Run with test parameters
	@nextflow run . -profile $(NXF_PROFILE) --task $(TASK) -stub-run


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