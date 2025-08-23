# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D 4GL platform with test tagging, filtering, and CI/CD integration.

## Project Overview

This project provides a complete testing framework for 4D applications featuring:

- **Auto test discovery** - Finds test classes ending with "Test"  
- **Comment-based tagging** - Organize tests with `// #tags: unit, integration, slow`
- **Flexible filtering** - Run specific test subsets by name, pattern, or tags
- **Multiple output formats** - Human-readable and JSON output with terse/verbose modes
- **CI/CD ready** - Structured JSON output for automated testing pipelines
- **Parallel test execution** - Run test suites concurrently for improved performance
- **Automatic transaction management** - Test isolation with automatic rollback
- **Manual transaction control** - Full transaction lifecycle management for advanced scenarios

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

# JUnit XML output for CI/CD integration
make test-junit             # Run all tests with JUnit XML output
make test-ci                # Run tests for CI/CD (saves to test-results/junit.xml)
make test-unit-junit        # Run unit tests with JUnit XML output
make test-integration-junit # Run integration tests with JUnit XML output

# Parallel execution
make test-parallel          # Run all tests in parallel
make test-parallel-json     # Run tests in parallel with JSON output
make test-parallel-unit     # Run unit tests in parallel
make test-parallel-workers WORKERS=4  # Run with custom worker count

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

# Run all tests with JUnit XML output (saves to test-results/junit.xml)
/Applications/tool4d.app/Contents/MacOS/tool4d --project $(PWD)/testing/Project/testing.4DProject --skip-onstartup --dataless --startup-method "test" --user-param "format=junit"
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
--user-param "format=junit tags=unit"
--user-param "format=junit outputPath=results/junit.xml"

# Parallel execution
--user-param "parallel=true"
--user-param "parallel=true maxWorkers=4"
--user-param "parallel=true format=json tags=unit"
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

## JUnit XML Output for CI/CD Integration

The framework supports JUnit XML output format for integration with GitLab CI/CD and other continuous integration systems.

### JUnit XML Features

- **GitLab Integration**: Test results appear in merge requests and pipeline views
- **File Artifacts**: XML files can be archived as CI artifacts for historical tracking
- **Test Navigation**: Direct links to failing test files in GitLab UI
- **Standard Format**: Compatible with Jenkins, CircleCI, and other CI tools
- **Detailed Reporting**: Includes test timing, failure messages, and stack traces

### Basic Usage

```bash
# Generate JUnit XML (saves to test-results/junit.xml)
make test-junit

# Custom output location
make test format=junit outputPath=custom/path/results.xml

# Combined with filtering
make test-unit-junit                    # Unit tests only
make test format=junit tags=integration # Integration tests only
```

### GitLab CI Integration

Add this to your `.gitlab-ci.yml`:

```yaml
test:
  script:
    - make test-ci  # Generates test-results/junit.xml
  artifacts:
    reports:
      junit: test-results/junit.xml
    paths:
      - test-results/
    when: always
    expire_in: 30 days
  coverage: '/Lines:\s*(\d+\.?\d*)%/'
```

### JUnit XML Structure

The generated XML includes:

- **Test Suites**: One per test class
- **Test Cases**: Individual test methods with timing
- **Failures**: Detailed failure messages with location info
- **File References**: Links to source test files
- **Timestamps**: Test execution timing for performance tracking

Example output structure:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="4D Test Results" tests="121" failures="0" errors="0" time="1.234">
  <testsuite name="_ExampleTest" tests="5" failures="0" errors="0" time="0.156">
    <testcase classname="_ExampleTest" name="test_areEqual_pass" 
              file="testing/Project/Sources/Classes/_ExampleTest.4dm" time="0.023"/>
  </testsuite>
</testsuites>
```

## Parallel Test Execution

The framework supports parallel execution of test suites to significantly reduce total test runtime while maintaining test isolation.

### Enabling Parallel Execution

```bash
# Enable parallel execution (uses CPU core count as default worker count)
make test-parallel

# Enable parallel execution with custom worker count
make test-parallel-workers WORKERS=4

# Combine parallel execution with other options
make test parallel=true format=json tags=unit maxWorkers=6
```

### How Parallel Execution Works

1. **Suite-Level Parallelism**: Test suites run concurrently, but individual tests within a suite run sequentially
2. **Worker Pool**: Creates worker processes up to the specified maximum (default: CPU core count, max: 8)
3. **Automatic Load Balancing**: Distributes test suites across available workers
4. **Test Isolation**: Each worker runs in its own process with separate transaction scope
5. **Result Aggregation**: Collects and merges results from all workers before generating final report

### Parallel Execution Opt-Out

Test suites can opt out of parallel execution using comment annotations:

```4d
// Test class that requires sequential execution
// #parallel: false

Class constructor()

Function test_database_exclusive_operation($t : cs:Testing)
    // This test requires exclusive database access
    // and will run sequentially even in parallel mode
```

### Performance Benefits

- **30-60% reduction** in total test runtime for typical test suites
- **Better resource utilization** on multi-core machines  
- **Improved developer experience** with faster feedback loops
- **CI/CD optimization** reducing pipeline duration

### Best Practices for Parallel Execution

1. **Design for Independence**: Ensure test suites don't depend on each other's state
2. **Use Transactions**: Leverage automatic transaction management for database isolation
3. **Opt-Out When Needed**: Use `// #parallel: false` for tests requiring exclusive resources
4. **Monitor Performance**: Compare sequential vs parallel execution times
5. **Tune Worker Count**: Adjust `maxWorkers` based on your hardware and test characteristics

## Transaction Management

The framework provides automatic transaction management for test isolation and manual transaction control for advanced scenarios.

### Automatic Transaction Management

By default, each test runs in its own transaction that is automatically rolled back after completion, ensuring:
- **Test Isolation**: Tests cannot interfere with each other's data
- **Clean Environment**: Database state is restored after each test
- **No Side Effects**: Failed tests don't leave partial data

### Controlling Transaction Behavior

Use comment-based annotations to control transaction behavior:

```4d
Function test_withTransactions($t : cs:C1710.Testing)
    // Automatic transactions enabled (default)
    // Test data changes will be rolled back
    
Function test_withoutTransactions($t : cs:C1710.Testing)  
    // #transaction: false
    // Disables automatic transaction management
```

### Manual Transaction Control

The Testing context provides methods for manual transaction management:

```4d
Function test_manualTransactions($t : cs:C1710.Testing)
    // #transaction: false
    
    // Start transaction manually
    $t.startTransaction()
    
    // Check transaction status
    If ($t.inTransaction())
        // Perform database operations
    End if
    
    // Validate or cancel transaction
    If ($success)
        $t.validateTransaction()
    Else
        $t.cancelTransaction()  
    End if

Function test_transactionWrapper($t : cs:C1710.Testing)
    // #transaction: false
    
    // Execute operation within transaction (auto-rollback)
    var $success : Boolean
    $success:=$t.withTransaction(Formula(
        // Database operations here
        // Will be rolled back automatically
    ))
    
    // Execute operation with validation (persists data)
    $success:=$t.withTransactionValidate(Formula(
        // Database operations here  
        // Will be validated if test succeeds
    ))
```

### Transaction Control Comments

| Comment                  | Effect                                   |
| ------------------------ | ---------------------------------------- |
| `// #transaction: false` | Disables automatic transactions          |
| No comment               | Enables automatic transactions (default) |