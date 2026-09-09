SHELL := /bin/bash

EXAMPLES := $(wildcard examples/*)

.PHONY: help fmt fmt-check docs docs-check init validate test test-dependencies lint security examples-init examples-validate check hooks

help:
	@echo "Available targets:"
	@echo "  make fmt                Format all Terraform files"
	@echo "  make fmt-check          Check Terraform formatting"
	@echo "  make docs               Generate README Terraform docs"
	@echo "  make docs-check         Check README Terraform docs are current"
	@echo "  make init               Initialize the root module"
	@echo "  make validate           Validate the root module"
	@echo "  make test               Run native Terraform tests"
	@echo "  make test-dependencies  Check endpoint dependencies in the Terraform graph"
	@echo "  make lint               Run TFLint with the Terraform and AWS rulesets"
	@echo "  make security           Scan Terraform configuration with Trivy"
	@echo "  make examples-init      Initialize all examples"
	@echo "  make examples-validate  Validate all examples"
	@echo "  make check              Run local CI-style checks"
	@echo "  make hooks              Enable repo-local Git hooks"

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive

docs:
	scripts/terraform-docs.sh

docs-check:
	scripts/terraform-docs.sh --check

init:
	terraform init -backend=false

validate:
	terraform validate

test:
	terraform test -no-color

test-dependencies:
	python3 scripts/check-endpoint-dependencies.py

lint:
	tflint --init
	tflint --recursive --format compact --config "$(CURDIR)/.tflint.hcl"

security:
	trivy config --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .terraform .

examples-init:
	@set -e; for example in $(EXAMPLES); do \
		if [ -d "$$example" ]; then \
			echo "Initializing $$example"; \
			terraform -chdir="$$example" init -backend=false; \
		fi; \
	done

examples-validate:
	@set -e; for example in $(EXAMPLES); do \
		if [ -d "$$example" ]; then \
			echo "Validating $$example"; \
			terraform -chdir="$$example" validate; \
		fi; \
	done

check: fmt-check docs-check init validate test test-dependencies examples-init examples-validate

hooks:
	git config core.hooksPath .githooks
