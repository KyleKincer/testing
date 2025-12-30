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
- **Trigger control** - Automatically skip database triggers during tests for true isolation

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

# Trigger control
--user-param "triggers=enabled"   # Enable triggers for all tests
--user-param "triggers=disabled"  # Disable triggers (default)
--user-param "triggers=enabled tags=integration"  # Enable triggers for integration tests
```

### Current Test Status

- **Total Tests**: 165 tests across 16 test suites
- **Pass Rate**: 100% (164 passed, 1 skipped)
- **Key Test Classes**: TaggingSystemTest, TriggerControlTest, TestRunnerTest, TransactionExampleTest

## Project Structure

```
testing/Project/Sources/Classes/
├── TestRunner.4dm       # Main test orchestration
├── TestSuite.4dm        # Individual test class management  
├── TestFunction.4dm     # Single test execution & tagging
├── TestAssertion.4dm           # Assertion library
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

## Trigger Control During Tests

The framework automatically disables database triggers during test execution to ensure true unit test isolation. This prevents external dependencies and side effects from interfering with tests.

### How It Works

When tests run (either via `tool4d` or from a host project), the framework sets a flag in 4D's shared `Storage`:

```4d
Storage.triggersDisabled.testMode = True
```

This flag remains set for the duration of the test run, allowing triggers in the host project to check and skip execution during testing.

### Running Tests from a Host Project

When running tests from a host project (not standalone), you **must** pass the host project's Storage object to enable trigger control:

```4d
// In your host project's method to run tests
var $hostStorage : Object
var $userParams : Object

$hostStorage:=Storage  // Pass the host project's Storage
$userParams:=New object  // Optional parameters (e.g., "triggers"; "enabled")

// Call the testing component method with cs, Storage, and optional user params
Testing_RunTestsWithCs(cs; $hostStorage; $userParams)
```

**Important:** Components have separate Storage objects from their host projects. By passing the host's Storage, the test framework can set flags that your host project's triggers can check.

### Implementing Trigger Control in Host Projects

To make triggers skip execution during tests, add this check at the beginning of each trigger:

```4d
// At the start of your trigger code
If (Storage.triggersDisabled#Null) && (Storage.triggersDisabled.testMode=True)
    return  // Skip trigger execution during tests
End if

// Normal trigger logic continues here...
```

### Example: Complete Trigger Implementation

```4d
// Table trigger with test mode support
If (Storage.triggersDisabled#Null) && (Storage.triggersDisabled.testMode=True)
    return
End if

// Normal trigger logic
Case of
    : (Trigger event=On Saving New Record Event)
        // Validate and set default values
        If ([MyTable]requiredField="")
            [MyTable]requiredField:="DefaultValue"
        End if

    : (Trigger event=On Saving Existing Record Event)
        // Update modification timestamp
        [MyTable]modifiedAt:=Current date
End case
```

### Benefits of Trigger Control

- **True Unit Testing**: Tests can focus on business logic without trigger side effects
- **Faster Tests**: Skipping triggers reduces test execution time
- **Test Isolation**: Each test runs in a clean state without trigger interference
- **Flexibility**: Easily enable triggers for integration tests when needed

### Configuring Trigger Behavior

The framework provides flexible control over when triggers execute:

#### Global Trigger Control via User Parameters

Control the default trigger behavior for all tests using the `triggers` parameter:

```bash
# Enable triggers for all tests (default is disabled)
make test triggers=enabled

# Explicitly disable triggers (default behavior)
make test triggers=disabled

# With other parameters
make test format=json triggers=enabled tags=integration
```

**Default Behavior**: Triggers are **disabled by default** (`triggers=disabled`) to ensure true unit test isolation.

#### Per-Test Trigger Control via Comments

Individual tests can override the global setting using comment annotations:

```4d
// #triggers: enabled
Function test_withTriggersEnabled($t : cs.Testing)
    // This test will have triggers enabled regardless of global setting
    // Useful for integration tests that need to verify trigger behavior

// #triggers: disabled
Function test_withTriggersDisabled($t : cs.Testing)
    // This test will have triggers disabled regardless of global setting
    // Useful for unit tests that need isolation

Function test_defaultBehavior($t : cs.Testing)
    // No annotation - uses global setting from triggers parameter
```

#### Use Cases

**Unit Tests (triggers disabled):**
```4d
// #triggers: disabled
Function test_calculateTotal($t : cs.Testing)
    // Test business logic without trigger side effects
    // Default behavior - no annotation needed
```

**Integration Tests (triggers enabled):**
```4d
// #tags: integration
// #triggers: enabled
Function test_orderProcessingWithTriggers($t : cs.Testing)
    // Test complete flow including trigger execution
```

**Hybrid Approach:**
```bash
# Run unit tests with triggers disabled (default)
make test-unit

# Run integration tests with triggers enabled
make test-integration triggers=enabled
```

### When to Allow Triggers

For integration tests that specifically need to test trigger behavior:

1. **Use per-test annotations** with `// #triggers: enabled`
2. **Enable globally** with `triggers=enabled` parameter for integration test suites
3. **Tag appropriately** using `// #tags: integration` for filtering
4. **Test trigger logic directly** by extracting it into testable functions
5. **Mock trigger behavior** in unit tests using test doubles

### Implementation Notes

- The `Storage.triggersDisabled.testMode` flag is automatically managed by the test framework
- Per-test trigger control automatically restores the default behavior after each test
- No manual cleanup is required - flags persist only for the test process lifetime
- Works in both interpreted and compiled modes
- Compatible with parallel test execution - each worker process has its own Storage state
- Test-level annotations take precedence over global `triggers` parameter