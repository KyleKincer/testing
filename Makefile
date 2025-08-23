# 4D Unit Testing Framework Makefile

# Get current user's home directory
HOME_DIR := $(shell echo $$HOME)

# Determine operating system
UNAME_S := $(shell uname -s)

# 4D tool path and default exclusion tags
ifeq ($(UNAME_S),Darwin)
TOOL4D := /Applications/tool4d.app/Contents/MacOS/tool4d
else
TOOL4D := /opt/tool4d/tool4d
DEFAULT_EXCLUDE_TAGS := no-linux
endif

# URL for downloading tool4d by platform
TOOL4D_URL_LINUX := https://resources-download.4d.com/release/20%20Rx/latest/latest/linux/tool4d.deb

# Project path relative to current directory
PROJECT_PATH := $(PWD)/testing/Project/testing.4DProject

# Base command options
BASE_OPTS := --project $(PROJECT_PATH) --skip-onstartup --dataless --startup-method "test"

# Default target
.DEFAULT_GOAL := test

# Internal helpers for tag handling
empty :=
space := $(empty) $(empty)
comma := ,

EXCLUDE_TAGS_COMBINED := $(strip $(DEFAULT_EXCLUDE_TAGS) $(excludeTags))
BASE_PARAMS := $(if $(EXCLUDE_TAGS_COMBINED),excludeTags=$(subst $(space),$(comma),$(EXCLUDE_TAGS_COMBINED)))

# Build user parameters from make variables
USER_PARAMS := $(strip $(BASE_PARAMS) $(if $(format),format=$(format)) $(if $(tags),tags=$(tags)) $(if $(test),test=$(test)) $(if $(requireTags),requireTags=$(requireTags)) $(if $(parallel),parallel=$(parallel)) $(if $(maxWorkers),maxWorkers=$(maxWorkers)))

# Ensure tool4d is installed (currently implemented for Linux only)
$(TOOL4D):
	@echo "tool4d not found at $(TOOL4D). Installing..."
	@if [ "$(UNAME_S)" = "Linux" ]; then \
	        apt-get update && \
	        apt-get install -y curl libc++1 uuid-runtime libfreeimage3 xdg-user-dirs; \
	        curl -L -o /tmp/libtinfo5.deb http://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/libtinfo5_6.1-1ubuntu1_amd64.deb; \
	        curl -L -o /tmp/libncurses5.deb http://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/libncurses5_6.1-1ubuntu1_amd64.deb; \
	        dpkg -i /tmp/libtinfo5.deb /tmp/libncurses5.deb; \
	        curl -L -o /tmp/tool4d.deb $(TOOL4D_URL_LINUX); \
	        dpkg --force-depends -i /tmp/tool4d.deb; \
	else \
	        echo "Automatic installation for $(UNAME_S) not implemented. Please install tool4d manually."; \
	        exit 1; \
	fi

# Run all tests with human-readable output
# Usage: make test [key=value key2=value2 ...]
# Example: make test format=json tags=unit
test: $(TOOL4D)
	@if [ -n "$(USER_PARAMS)" ]; then \
	        $(TOOL4D) $(BASE_OPTS) --user-param "$(USER_PARAMS)"; \
	else \
	        $(TOOL4D) $(BASE_OPTS); \
	fi

# Run all tests with JSON output
test-json:
	$(MAKE) test format=json

# Run specific test class (usage: make test-class CLASS=ExampleTest)
test-class:
	$(MAKE) test test=$(CLASS)

# Run tests by tags (usage: make test-tags TAGS=unit)
test-tags:
	$(MAKE) test tags=$(TAGS)

# Run tests excluding tags (usage: make test-exclude-tags TAGS=slow)
test-exclude-tags:
	$(MAKE) test excludeTags=$(TAGS)

# Run tests requiring specific tags (usage: make test-require-tags TAGS=unit,fast)
test-require-tags:
	$(MAKE) test requireTags=$(TAGS)

# Run unit tests only
test-unit:
	$(MAKE) test tags=unit

# Run integration tests only
test-integration:
	$(MAKE) test tags=integration

# Run tests with JSON output and unit tag
test-unit-json:
	$(MAKE) test format=json tags=unit

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

# Run tests in parallel mode
test-parallel:
	$(TOOL4D) $(BASE_OPTS) --user-param "parallel=true"

# Run tests in parallel mode with JSON output
test-parallel-json:
	$(TOOL4D) $(BASE_OPTS) --user-param "parallel=true format=json"

# Run unit tests in parallel mode
test-parallel-unit:
	$(TOOL4D) $(BASE_OPTS) --user-param "parallel=true tags=unit"

# Run tests in parallel with custom worker count (usage: make test-parallel-workers WORKERS=4)
test-parallel-workers:
	$(TOOL4D) $(BASE_OPTS) --user-param "parallel=true maxWorkers=$(WORKERS)"

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
	@echo "  test-parallel       - Run tests in parallel mode"
	@echo "  test-parallel-json  - Run tests in parallel with JSON output"
	@echo "  test-parallel-unit  - Run unit tests in parallel"
	@echo "  test-parallel-workers - Run tests in parallel with custom worker count"
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
	@echo "  make test-parallel"
	@echo "  make test-parallel-json"
	@echo "  make test-parallel-workers WORKERS=4"
	@echo "  make test parallel=true maxWorkers=6"

tool4d: $(TOOL4D)
	@echo "tool4d ready at $(TOOL4D)"

.PHONY: test test-json test-junit test-ci test-class test-tags test-exclude-tags test-require-tags test-unit test-integration test-unit-json test-unit-junit test-integration-junit test-parallel test-parallel-json test-parallel-unit test-parallel-workers help tool4d
