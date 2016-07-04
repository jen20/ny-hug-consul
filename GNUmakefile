TERRAFORM_REMOTE_STATE_NAME="ny-hug/consul"

PACKER_SOURCE_AMI=ami-191fd379
PACKER_REGION=us-west-2

default: help

.PHONY: help
help:
	@echo "Valid targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: ami
ami: ## Build a Consul Server AMI using Packer
	@packer build \
		-var "source_ami=$(PACKER_SOURCE_AMI)" \
		-var "region=$(PACKER_REGION)" \
		packer/template.json

.PHONY: config
config: ## Configure Terraform Remote State Storage
	@echo "Configuring Terraform remote state ($(TERRAFORM_REMOTE_STATE_KEY))..."
	@terraform remote config \
		-backend=atlas \
		-backend-config="name=$(TERRAFORM_REMOTE_STATE_NAME)"

.PHONY: plan
plan: ## Run a Terraform plan operation - set TF_OPTS for additional flags
	@terraform get $(TF_OPTS) terraform/
	@terraform plan $(TF_OPTS) terraform/

.PHONY: apply
apply: ## Run a Terraform apply operation - set TF_OPTS for additional flags
	@terraform apply $(TF_OPTS) terraform/

.PHONY: destroy
destroy: ## Run a Terraform destroy operation - set TF_OPTS for additional flags
	@terraform destroy $(TF_OPTS) terraform/

.PHONY: output
output: ## Show Terraform outputs - set TF_OPTS for individual fields
	@terraform output $(TF_OPTS)
