# 4D Unit Testing Framework Makefile

# Get current user's home directory
HOME_DIR := $(shell echo $$HOME)

# 4D tool path
TOOL4D := /Applications/tool4d.app/Contents/MacOS/tool4d

# Project path relative to current directory
PROJECT_PATH := $(PWD)/testing/Project/testing.4DProject

# Base command options
BASE_OPTS := --project $(PROJECT_PATH) --skip-onstartup --dataless --startup-method "test"

# Default target
.DEFAULT_GOAL := test

# Build user parameters from make variables
USER_PARAMS := $(strip $(if $(format),format=$(format)) $(if $(tags),tags=$(tags)) $(if $(test),test=$(test)) $(if $(excludeTags),excludeTags=$(excludeTags)) $(if $(requireTags),requireTags=$(requireTags)))

# Run all tests with human-readable output  
# Usage: make test [key=value key2=value2 ...]
# Example: make test format=json tags=unit
test:
	@if [ -n "$(USER_PARAMS)" ]; then \
		$(TOOL4D) $(BASE_OPTS) --user-param "$(USER_PARAMS)"; \
	else \
		$(TOOL4D) $(BASE_OPTS); \
	fi

# Run all tests with JSON output
test-json:
	$(TOOL4D) $(BASE_OPTS) --user-param "format=json"

# Run specific test class (usage: make test-class CLASS=ExampleTest)
test-class:
	$(TOOL4D) $(BASE_OPTS) --user-param "test=$(CLASS)"

# Run tests by tags (usage: make test-tags TAGS=unit)
test-tags:
	$(TOOL4D) $(BASE_OPTS) --user-param "tags=$(TAGS)"

# Run tests excluding tags (usage: make test-exclude-tags TAGS=slow)
test-exclude-tags:
	$(TOOL4D) $(BASE_OPTS) --user-param "excludeTags=$(TAGS)"

# Run tests requiring specific tags (usage: make test-require-tags TAGS=unit,fast)
test-require-tags:
	$(TOOL4D) $(BASE_OPTS) --user-param "requireTags=$(TAGS)"

# Run unit tests only
test-unit:
	$(TOOL4D) $(BASE_OPTS) --user-param "tags=unit"

# Run integration tests only
test-integration:
	$(TOOL4D) $(BASE_OPTS) --user-param "tags=integration"

# Run tests with JSON output and unit tag
test-unit-json:
	$(TOOL4D) $(BASE_OPTS) --user-param "format=json tags=unit"

# Run all tests with JUnit XML output
test-junit:
	$(TOOL4D) $(BASE_OPTS) --user-param "format=junit"

# Run tests for CI/CD with custom output path
test-ci:
	$(TOOL4D) $(BASE_OPTS) --user-param "format=junit outputPath=test-results/junit.xml"

# Run unit tests with JUnit XML output
test-unit-junit:
	$(TOOL4D) $(BASE_OPTS) --user-param "format=junit tags=unit"

# Run integration tests with JUnit XML output
test-integration-junit:
	$(TOOL4D) $(BASE_OPTS) --user-param "format=junit tags=integration"

# Show help
help:
	@echo "4D Unit Testing Framework Commands:"
	@echo ""
	@echo "  test [params]       - Run tests with optional parameters"
	@echo "  test-json           - Run all tests with JSON output"
	@echo "  test-junit          - Run all tests with JUnit XML output"
	@echo "  test-ci             - Run tests for CI/CD (JUnit XML to test-results/)"
	@echo "  test-class          - Run specific test class (CLASS=ExampleTest)"
	@echo "  test-tags           - Run tests by tags (TAGS=unit)"
	@echo "  test-exclude-tags   - Run tests excluding tags (TAGS=slow)"
	@echo "  test-require-tags   - Run tests requiring tags (TAGS=unit,fast)"
	@echo "  test-unit           - Run unit tests only"
	@echo "  test-integration    - Run integration tests only"
	@echo "  test-unit-json      - Run unit tests with JSON output"
	@echo "  test-unit-junit     - Run unit tests with JUnit XML output"
	@echo "  test-integration-junit - Run integration tests with JUnit XML output"
	@echo "  help                - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make test format=json"
	@echo "  make test format=junit"
	@echo "  make test tags=unit"
	@echo "  make test format=json tags=unit excludeTags=slow"
	@echo "  make test format=junit outputPath=results/junit.xml"
	@echo "  make test test=ExampleTest"
	@echo "  make test-class CLASS=TaggingSystemTest"
	@echo "  make test-tags TAGS=unit,fast"
	@echo "  make test-exclude-tags TAGS=slow"
	@echo "  make test-junit"
	@echo "  make test-ci"

.PHONY: test test-json test-junit test-ci test-class test-tags test-exclude-tags test-require-tags test-unit test-integration test-unit-json test-unit-junit test-integration-junit help