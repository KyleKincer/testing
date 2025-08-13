# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D 4GL platform with test tagging, filtering, and CI/CD integration.

## Project Overview

This project provides a complete testing framework for 4D applications featuring:

- **Auto test discovery** - Finds test classes ending with "Test"  
- **Comment-based tagging** - Organize tests with `// #tags: unit, integration, slow`
- **Flexible filtering** - Run specific test subsets by name, pattern, or tags
- **Multiple output formats** - Human-readable and JSON output with terse/verbose modes
- **CI/CD ready** - Structured JSON output for automated testing pipelines

## Running Tests

### Quick Start with Makefile

```bash
# Run all tests
make test

# Pass parameters directly to test command
make test format=json
make test tags=unit
make test format=json tags=unit excludeTags=slow
make test test=ExampleTest

# Alternative named commands
make test-json              # Run all tests with JSON output
make test-class CLASS=ExampleTest
make test-tags TAGS=unit
make test-tags TAGS=integration,performance
make test-exclude-tags TAGS=slow
make test-require-tags TAGS=unit,fast

# Convenience shortcuts  
make test-unit              # Run only unit tests
make test-integration       # Run only integration tests
make test-unit-json         # Run unit tests with JSON output

# Show all available commands
make help
```

### Manual Test Execution (Advanced)

If you need more control or the Makefile doesn't meet your needs:

```bash
# Run all tests with human output
/Applications/tool4d.app/Contents/MacOS/tool4d --project $(PWD)/testing/Project/testing.4DProject --skip-onstartup --dataless --startup-method "test"

# Run all tests with JSON output  
/Applications/tool4d.app/Contents/MacOS/tool4d --project $(PWD)/testing/Project/testing.4DProject --skip-onstartup --dataless --startup-method "test" --user-param "format=json"
```

### Test Filtering Parameters

```bash
# Run specific test class
--user-param "test=ExampleTest"

# Run tests by tags
--user-param "tags=unit"
--user-param "tags=integration,performance" 
--user-param "excludeTags=slow"
--user-param "requireTags=unit,fast"

# Combined filtering
--user-param "tags=unit excludeTags=slow"
--user-param "format=json tags=integration"
```

### Current Test Status

- **Total Tests**: 121 tests across 14 test suites
- **Pass Rate**: 100% 
- **Key Test Classes**: TaggingSystemTest, TaggingExampleTest, TestRunnerTest, TestSuiteTest

## Project Structure

```
testing/Project/Sources/Classes/
├── TestRunner.4dm       # Main test orchestration
├── TestSuite.4dm        # Individual test class management  
├── TestFunction.4dm     # Single test execution & tagging
├── Assert.4dm           # Assertion library
├── Testing.4dm          # Test context
├── TaggingExampleTest.4dm    # Tagging examples
├── TaggingSystemTest.4dm     # Tagging functionality tests
└── [other test classes]
```

The framework automatically discovers and runs any class ending with "Test" that contains methods starting with "test_".