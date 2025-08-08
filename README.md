# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D 4GL platform with enhanced reporting, JSON output, and CI/CD integration.

## Features

- **Auto Test Discovery**: Automatically finds test classes ending with "Test" and test methods starting with "test_"
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

Function test_addition_works($t : cs.Testing)
    var $assert : cs.Assert
    $assert:=cs.Assert.new()
    $assert.areEqual($t; 5; 2+3; "Addition should work correctly")

Function test_string_comparison($t : cs.Testing)
    var $assert : cs.Assert
    $assert:=cs.Assert.new()
    $assert.areEqual($t; "hello"; "hello"; "Strings should be equal")
```

### 2. Run Tests

```bash
# Human-readable output
tool4d --project YourProject.4DProject --startup-method "test"

# JSON output for CI/CD
tool4d --project YourProject.4DProject --startup-method "test" --user-param "json"
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
    var $assert : cs.Assert
    $assert:=cs.Assert.new()
    
    var $user : Object
    $user:=New object("name"; "John"; "email"; "john@example.com")
    
    $assert.isNotNull($t; $user.name; "User should have a name")
    $assert.areEqual($t; "John"; $user.name; "User name should be correct")
    $assert.isTrue($t; $user.email#""; "User should have an email")
```

## Assertion Library

The `cs.Assert` class provides comprehensive assertion methods:

### Basic Assertions
- `areEqual($t; $expected; $actual; $message)` - Values must be equal
- `isTrue($t; $value; $message)` - Value must be true
- `isFalse($t; $value; $message)` - Value must be false
- `isNull($t; $value; $message)` - Value must be null
- `isNotNull($t; $value; $message)` - Value must not be null
- `fail($t; $message)` - Force test failure

### Usage Example
```4d
Function test_calculations($t : cs.Testing)
    var $assert : cs.Assert
    $assert:=cs.Assert.new()
    
    // Test equality
    $assert.areEqual($t; 10; 5*2; "Multiplication should work")
    
    // Test boolean conditions
    $assert.isTrue($t; (10>5); "10 should be greater than 5")
    $assert.isFalse($t; (5>10); "5 should not be greater than 10")
    
    // Test null checks
    var $result : Object
    $result:=someFunction()
    $assert.isNotNull($t; $result; "Function should return a result")
```

## Output Formats

### Human-Readable Output (Default)

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

Enable with `--user-param "json"`:

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
          "suite": "ExampleTest"
        }
      ],
      "passed": 5,
      "failed": 0
    }
  ],
  "failedTests": []
}
```

## Mocking and Test Utilities

### UnitStatsTracker

Track function calls and parameters for mocking:

```4d
var $tracker : cs.UnitStatsTracker
$tracker:=cs.UnitStatsTracker.new()

// Mock a function call
var $result : Variant
$result:=$tracker.mock("getUserData"; ["user123"]; New object("name"; "John"))

// Verify the call was made
var $stat : cs.UnitStatsDetail
$stat:=$tracker.getStat("getUserData")
$assert.areEqual($t; 1; $stat.getNumberOfCalls(); "Function should be called once")
$assert.areEqual($t; "user123"; $stat.getXCallYParameter(1; 1); "First parameter should be user123")
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
                 --user-param "json" > test-results.json
          
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
- **`cs.Testing`**: Test context passed to each test method
- **`cs.Assert`**: Assertion library for test validation
- **`cs.UnitStatsTracker`**: Mock function call tracking
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
$assert.areEqual($t; "active"; $user.status; "User status should be active after registration")

// Less helpful
$assert.areEqual($t; "active"; $user.status; "Status check failed")
```

### Test Independence
- Each test should be independent and not rely on other tests
- Use setup/teardown for test data preparation
- Avoid shared state between tests

## License

MIT License - see LICENSE file for details.