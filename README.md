# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D 4GL platform with enhanced reporting, JSON output, and CI/CD integration.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Writing Tests](#writing-tests)
- [Assertion Library](#assertion-library)
- [Output Formats](#output-formats)
- [Test Filtering](#test-filtering)
- [Test Tagging](#test-tagging)
- [Mocking and Test Utilities](#mocking-and-test-utilities)
- [CI/CD Integration](#cicd-integration)
- [Framework Architecture](#framework-architecture)
- [Best Practices](#best-practices)
- [License](#license)

## Features

- **Auto Test Discovery**: Automatically finds test classes ending with "Test" and test methods starting with "test_"
- **Test Filtering**: Run specific tests by name/pattern with wildcard support
- **Test Tagging**: Organize and filter tests using comment-based tags
- **Rich Assertions**: Built-in assertion library with helpful error messages
- **Enhanced Reporting**: Detailed test results with execution times and pass rates
- **JSON Output**: Structured output for CI/CD integration and automated processing
- **Mock Support**: Built-in mocking utilities for isolated unit testing
- **CI/CD Ready**: GitHub Actions integration for automated testing

## Quick Start

### 1. Create a Test Class

Test classes must end with "Test":

```4d
// ExampleTest.4dm
Class constructor()

// #tags: unit, math
Function test_addition_works($t : cs.Testing)
    $t.assert.areEqual($t; 5; 2+3; "Addition should work correctly")

// #tags: unit, string
Function test_string_comparison($t : cs.Testing)
    $t.assert.areEqual($t; "hello"; "hello"; "Strings should be equal")
```

### 2. Run Tests

```bash
# Human-readable output (terse by default)
tool4d --project YourProject.4DProject --startup-method "test"

# Verbose human-readable output
tool4d --project YourProject.4DProject --startup-method "test" --user-param "verbose=true"

# JSON output for CI/CD (terse by default)
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json"

# Verbose JSON output
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json verbose=true"

# Run specific tests by pattern
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=ExampleTest"

# Run tests by tags
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit"

# Exclude slow tests
tool4d --project YourProject.4DProject --startup-method "test" --user-param "excludeTags=slow"

# Combine multiple parameters
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json tags=unit,integration verbose=true"
```

## Writing Tests

### Test Class Requirements

- Class name must end with "Test" (e.g., `UserServiceTest`, `ExampleTest`)
- Test methods must start with "test_" (e.g., `test_user_creation`, `test_validation`)
- Test methods receive a `$t : cs.Testing` parameter

### Basic Example

```4d
Class constructor()

Function test_user_validation($t : cs.Testing)
    var $user : Object
    $user:=New object("name"; "John"; "email"; "john@example.com")
    
    $t.assert.isNotNull($t; $user.name; "User should have a name")
    $t.assert.areEqual($t; "John"; $user.name; "User name should be correct")
    $t.assert.isTrue($t; $user.email#""; "User should have an email")
```

## Assertion Library

The framework includes built-in assertion methods accessible through `$t.assert`:

### Basic Assertions
- `$t.assert.areEqual($t; $expected; $actual; $message)` - Values must be equal
- `$t.assert.isTrue($t; $value; $message)` - Value must be true
- `$t.assert.isFalse($t; $value; $message)` - Value must be false
- `$t.assert.isNull($t; $value; $message)` - Value must be null
- `$t.assert.isNotNull($t; $value; $message)` - Value must not be null
- `$t.assert.fail($t; $message)` - Force test failure

### Usage Example
```4d
Function test_calculations($t : cs.Testing)
    // Test equality
    $t.assert.areEqual($t; 10; 5*2; "Multiplication should work")
    
    // Test boolean conditions
    $t.assert.isTrue($t; (10>5); "10 should be greater than 5")
    $t.assert.isFalse($t; (5>10); "5 should not be greater than 10")
    
    // Test null checks
    var $result : Object
    $result:=someFunction()
    $t.assert.isNotNull($t; $result; "Function should return a result")
```

## Output Formats

The framework provides terse output by default for cleaner results, with verbose mode available when more detail is needed.

### Human-Readable Output

**Terse (Default):**
```
  ✓ test_areEqual_pass
  ✓ test_isTrue_pass
  ✓ test_isFalse_pass
  ✓ test_isNull_pass
  ✓ test_isNotNull_pass

5 tests passed
```

**Verbose (`verbose=true`):**
```
=== 4D Unit Testing Framework ===
Running tests...

  ✓ test_areEqual_pass (1ms)
  ✓ test_isTrue_pass (0ms)
  ✓ test_isFalse_pass (1ms)
  ✓ test_isNull_pass (0ms)
  ✓ test_isNotNull_pass (1ms)

=== Test Results Summary ===
Total Tests: 5
Passed: 5
Failed: 0
Pass Rate: 100.0%
Duration: 45ms

All tests passed! 🎉
```

### JSON Output

**Terse (Default with `format=json`):**
```json
{
  "totalTests": 5,
  "passed": 5,
  "failed": 0,
  "duration": 45,
  "passRate": 100,
  "status": "success",
  "suites": [
    {
      "name": "ExampleTest",
      "passed": 5,
      "failed": 0,
      "tests": [
        {
          "name": "test_areEqual_pass",
          "passed": true
        }
      ]
    }
  ]
}
```

**Verbose (`format=json verbose=true`):**
```json
{
  "totalTests": 5,
  "passed": 5,
  "failed": 0,
  "skipped": 0,
  "startTime": 1641916800000,
  "endTime": 1641916800045,
  "duration": 45,
  "passRate": 100.0,
  "status": "success",
  "suites": [
    {
      "name": "ExampleTest",
      "tests": [
        {
          "name": "test_areEqual_pass",
          "passed": true,
          "failed": false,
          "duration": 1,
          "suite": "ExampleTest",
          "runtimeErrors": [],
          "logMessages": []
        }
      ],
      "passed": 5,
      "failed": 0
    }
  ],
  "failedTests": []
}
```

## Test Filtering

Run specific tests by name or pattern using the `test=` parameter:

### Filter by Test Suite

```bash
# Run all tests in ExampleTest suite
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=ExampleTest"

# Run all tests in multiple suites
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=ExampleTest,ErrorHandlingTest"
```

### Filter by Specific Test Method

```bash
# Run specific test method
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=ExampleTest.test_areEqual_pass"

# Run multiple specific methods
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=ExampleTest.test_areEqual_pass,ErrorHandlingTest.test_error_handler_initialization"
```

### Wildcard Filtering

```bash
# Run all test suites containing "Error" in the name
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=*Error*"

# Run all test methods starting with "test_setup"
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=*test_setup*"
```

### Combine with JSON Output

```bash
# Filter tests and get JSON output
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json test=ExampleTest"
```

## Parameter Format

The framework uses a standardized key=value parameter format:

```bash
# Use space-separated key=value pairs
--user-param "format=json test=ExampleTest"

# Alternative: use colon separators
--user-param "format:json test:ExampleTest"
```

### Available Parameters
- **`format`**: Output format (`json` or `human`)
- **`test`**: Test filtering patterns
- **`verbose`**: Enable verbose output (`true` or `1`)
- **`tags`**: Include tests with any of these tags (comma-separated)
- **`excludeTags`**: Exclude tests with any of these tags (comma-separated)
- **`requireTags`**: Include only tests with ALL of these tags (comma-separated)


### Pattern Matching Rules

- **Exact match**: `ExampleTest` runs all tests in the ExampleTest suite
- **Method-specific**: `ExampleTest.test_areEqual_pass` runs only that specific method
- **Wildcards**: Use `*` for pattern matching (e.g., `*Error*` matches anything containing "Error")
- **Multiple patterns**: Separate with commas: `ExampleTest,*Error*`
- **Case-sensitive**: Pattern matching is case-sensitive

## Test Tagging

The framework supports organizing and filtering tests using comment-based tags. Tags allow you to categorize tests and run specific subsets based on their characteristics.

### Defining Tags

Add tags to test methods using `#tags:` comments immediately before the function declaration:

```4d
Class constructor()

// #tags: unit, fast
Function test_basic_addition($t : cs.Testing)
    $t.assert.areEqual($t; 4; 2+2; "Addition should work")

// #tags: integration, slow
Function test_database_connection($t : cs.Testing)
    // Simulate slow database operation
    DELAY PROCESS(Current process; 10)
    $t.assert.isTrue($t; True; "Database connection test")

// #tags: unit, edge-case
Function test_empty_string_handling($t : cs.Testing)
    var $result : Text
    $result:=""+"test"
    $t.assert.areEqual($t; "test"; $result; "Empty string concatenation")

// #tags: integration, performance, external
Function test_file_system_access($t : cs.Testing)
    var $folder : 4D.Folder
    $folder:=Folder(fk desktop folder)
    $t.assert.isNotNull($t; $folder; "Should access desktop folder")
```

### Tag Syntax Rules

- Use `// #tags:` followed by comma-separated tag names
- Tags can contain letters, numbers, hyphens, and underscores
- Whitespace around tags is automatically trimmed
- Tests without explicit tags automatically receive the "unit" tag

### Tag Filtering Commands

#### Include Tags (OR Logic)
Run tests that have **any** of the specified tags:

```bash
# Run all fast tests
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=fast"

# Run tests tagged as either unit OR integration
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit,integration"

# JSON output with tag filtering
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json tags=performance"
```

#### Exclude Tags (Highest Priority)
Exclude tests that have **any** of the specified tags:

```bash
# Run all tests EXCEPT slow ones
tool4d --project YourProject.4DProject --startup-method "test" --user-param "excludeTags=slow"

# Exclude both slow and external tests
tool4d --project YourProject.4DProject --startup-method "test" --user-param "excludeTags=slow,external"

# Combine with JSON output
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json excludeTags=integration"
```

#### Require All Tags (AND Logic)
Run tests that have **all** of the specified tags:

```bash
# Run tests that are BOTH integration AND performance
tool4d --project YourProject.4DProject --startup-method "test" --user-param "requireTags=integration,performance"

# Run tests that are unit, fast, AND edge-case
tool4d --project YourProject.4DProject --startup-method "test" --user-param "requireTags=unit,fast,edge-case"
```

#### Combined Tag Filtering
You can combine multiple tag filtering options. **Exclude tags have the highest priority**:

```bash
# Run unit tests but exclude slow ones
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit excludeTags=slow"

# Run integration tests that are also performance tests, but exclude external ones
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=integration requireTags=performance excludeTags=external"

# Complex filtering with JSON output
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json tags=unit,integration excludeTags=slow requireTags=fast"
```

### Common Tagging Strategies

#### By Test Type
```4d
// #tags: unit
Function test_calculation_logic($t : cs.Testing)

// #tags: integration
Function test_api_integration($t : cs.Testing)

// #tags: e2e
Function test_complete_user_workflow($t : cs.Testing)
```

#### By Speed/Performance
```4d
// #tags: fast
Function test_quick_validation($t : cs.Testing)

// #tags: slow
Function test_large_dataset_processing($t : cs.Testing)

// #tags: performance
Function test_response_time_requirements($t : cs.Testing)
```

#### By Dependencies
```4d
// #tags: database
Function test_user_repository($t : cs.Testing)

// #tags: external, network
Function test_api_service($t : cs.Testing)

// #tags: filesystem
Function test_file_operations($t : cs.Testing)
```

#### By Feature/Component
```4d
// #tags: auth, security
Function test_login_validation($t : cs.Testing)

// #tags: billing, finance
Function test_payment_processing($t : cs.Testing)

// #tags: reporting, analytics
Function test_report_generation($t : cs.Testing)
```

### CI/CD Integration with Tags

Use tags to run different test suites in different CI/CD scenarios:

```yml
# Run only fast unit tests for PR validation
- name: Quick Tests
  run: tool4d --project testing.4DProject --startup-method "test" --user-param "format=json tags=unit,fast excludeTags=slow"

# Run integration tests separately
- name: Integration Tests  
  run: tool4d --project testing.4DProject --startup-method "test" --user-param "format=json tags=integration"

# Run performance tests on nightly builds
- name: Performance Tests
  run: tool4d --project testing.4DProject --startup-method "test" --user-param "format=json tags=performance"
```

### Tag Filtering Precedence

When multiple tag filters are specified, they are applied in this order:

1. **Exclude tags** (highest priority) - Tests with excluded tags are removed first
2. **Require all tags** - Tests must have ALL specified tags
3. **Include tags** - Tests must have at least ONE of the specified tags
4. **Default behavior** - If no tag filters are specified, all tests run

## Mocking and Test Utilities

### Built-in Stats Tracker

The framework includes built-in mocking capabilities accessible through `$t.stats`:

```4d
Function test_mock_example($t : cs.Testing)
    // Mock a function call
    var $result : Variant
    $result:=$t.stats.mock("getUserData"; ["user123"]; New object("name"; "John"))
    
    // Verify the call was made
    var $stat : cs.UnitStatsDetail
    $stat:=$t.stats.getStat("getUserData")
    $t.assert.areEqual($t; 1; $stat.getNumberOfCalls(); "Function should be called once")
    $t.assert.areEqual($t; "user123"; $stat.getXCallYParameter(1; 1); "First parameter should be user123")
```

### Advanced Mocking Example

```4d
Function test_multiple_mock_calls($t : cs.Testing)
    // Make multiple calls to the same mock
    $t.stats.mock("validateUser"; ["admin"]; True)
    $t.stats.mock("validateUser"; ["guest"]; False)
    
    // Verify both calls were tracked
    var $stat : cs.UnitStatsDetail
    $stat:=$t.stats.getStat("validateUser")
    
    $t.assert.areEqual($t; 2; $stat.getNumberOfCalls(); "Should be called twice")
    $t.assert.areEqual($t; "admin"; $stat.getXCallYParameter(1; 1); "First call should be admin")
    $t.assert.areEqual($t; "guest"; $stat.getXCallYParameter(2; 1); "Second call should be guest")
```

## CI/CD Integration

### GitHub Actions Example

```yml
name: Run Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run 4D Tests
        run: |
          tool4d --project testing/Project/testing.4DProject \
                 --skip-onstartup --dataless \
                 --startup-method "test" \
                 --user-param "format=json" > test-results.json
          
      - name: Check Test Results
        run: |
          if jq -e '.status == "failure"' test-results.json > /dev/null; then
            echo "Tests failed"
            exit 1
          fi
```

## Framework Architecture

### Core Classes

- **`cs.TestRunner`**: Discovers and executes test suites
- **`cs.TestSuite`**: Manages tests within a single test class  
- **`cs.TestFunction`**: Executes individual test methods
- **`cs.Testing`**: Test context with built-in assertion and mocking utilities
  - **`$t.assert`**: Built-in assertion library for test validation
  - **`$t.stats`**: Built-in mock function call tracking
- **`cs.Assert`**: Assertion implementation class
- **`cs.UnitStatsTracker`**: Mock tracking implementation class
- **`cs.UnitStatsDetail`**: Detailed call statistics

### Test Discovery

The framework automatically discovers:
1. Classes ending with "Test"
2. Methods starting with "test_" within those classes
3. Skips DataClass subclasses

### Execution Flow

1. `TestRunner` discovers all test classes
2. For each class, creates a `TestSuite`
3. `TestSuite` discovers test methods and creates `TestFunction` instances
4. Each `TestFunction` executes with timing and result tracking
5. Results are collected and reported in chosen format

## Best Practices

### Test Organization
- One test class per logical unit (e.g., `UserServiceTest`, `OrderProcessingTest`)
- Group related tests in the same class
- Use descriptive test method names: `test_user_creation_with_valid_data`

### Assertion Messages
- Always provide descriptive assertion messages
- Include expected vs actual values in messages
- Make failures easy to debug

```4d
// Good
$t.assert.areEqual($t; "active"; $user.status; "User status should be active after registration")

// Less helpful
$t.assert.areEqual($t; "active"; $user.status; "Status check failed")
```

### Test Independence
- Each test should be independent and not rely on other tests
- Use setup/teardown for test data preparation
- Avoid shared state between tests

## License

MIT License - see LICENSE file for details.