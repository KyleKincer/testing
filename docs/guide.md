# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D platform with enhanced reporting, JSON output, and CI/CD integration.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Required Setup](#required-setup)
- [Writing Tests](#writing-tests)
- [Assertion Library](#assertion-library)
- [Output Formats](#output-formats)
- [Test Filtering](#test-filtering)
- [Test Tagging](#test-tagging)
- [Test Lifecycle Methods](#test-lifecycle-methods)
- [Table-Driven Tests](#table-driven-tests)
- [Mocking and Test Utilities](#mocking-and-test-utilities)
- [CI/CD Integration](#cicd-integration)
- [Framework Architecture](#framework-architecture)
- [Best Practices](#best-practices)
- [Transaction Management](#transaction-management)
- [License](#license)

## Features

- **Auto Test Discovery**: Automatically finds test classes ending with "Test" and test methods starting with "test_"
- **Test Filtering**: Run specific tests by name/pattern with wildcard support
- **Test Tagging**: Organize and filter tests using comment-based tags
- **Rich Assertions**: Built-in assertion library with helpful error messages
- **Enhanced Reporting**: Detailed test results with execution times and pass rates
- **JSON Output**: Structured output for CI/CD integration and automated processing
- **Subtest Support**: Create table-driven tests using `t.run`
- **Mock Support**: Built-in mocking utilities for isolated unit testing
- **CI/CD Ready**: GitHub Actions integration for automated testing

## Quick Start

### 1. Create a Test Class

Test classes must end with "Test":

```4d
// ExampleTest.4dm
Class constructor()

// #tags: unit, math
Function test_addition_works($t : cs.Testing.Testing)
    $t.assert.areEqual($t; 5; 2+3; "Addition should work correctly")

// #tags: unit, string
Function test_string_comparison($t : cs.Testing.Testing)
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

## Required Setup

### Creating the Startup Method

To run tests using the tool4d commands, you must create a project method to serve as the startup method. This method bridges your host project with the testing component.

Create a project method (e.g., named "test") with the following code:

```4d
var $runner : cs.Testing.TestRunner
$runner:=cs.Testing.TestRunner.new(cs)

$runner.run()
```

**Important:** You must pass the host project's class store (`cs`) to the component's `TestRunner.new()` method. This allows the testing component to discover and run test classes from your host project.

### Why This is Required

The testing framework needs access to your project's class store to:
- Discover test classes ending with "Test"
- Instantiate test classes from your project
- Execute test methods within the correct context

Without passing the host project's class store, the framework cannot access your test classes since they exist in the host project rather than the component.

## Writing Tests

### Test Class Requirements

- Class name must end with "Test" (e.g., `UserServiceTest`, `ExampleTest`)
- Test methods must start with "test_" (e.g., `test_user_creation`, `test_validation`)
- Test methods receive a `$t : cs.Testing.Testing` parameter

### Basic Example

```4d
Class constructor()

Function test_user_validation($t : cs.Testing.Testing)
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
- `$t.assert.areDeepEqual($t; $expected; $actual; $message; $maxDepth)` - Deep equality comparison for objects and collections (optional `$maxDepth`, default: 10)
- `$t.assert.isTrue($t; $value; $message)` - Value must be true
- `$t.assert.isFalse($t; $value; $message)` - Value must be false
- `$t.assert.isNull($t; $value; $message)` - Value must be null
- `$t.assert.isNotNull($t; $value; $message)` - Value must not be null
- `$t.assert.fail($t; $message)` - Force test failure
- `$t.assert.contains($t; $container; $value; $message)` - Text or collection must contain value

### Usage Example
```4d
Function test_calculations($t : cs.Testing.Testing)
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

### Deep Equality Assertions

The `areDeepEqual` function performs recursive comparison of nested objects and collections, providing detailed difference reporting when values don't match. This is especially useful for testing complex data structures.

**Basic Usage:**
```4d
Function test_object_comparison($t : cs.Testing.Testing)
    var $expected; $actual : Object
    $expected:={name: "John"; age: 30; address: {city: "New York"; zip: "10001"}}
    $actual:={name: "John"; age: 30; address: {city: "New York"; zip: "10001"}}
    
    // Deep comparison of nested structures
    $t.assert.areDeepEqual($t; $expected; $actual; "Objects should match")
```

**With Custom Max Depth:**
```4d
Function test_deep_nesting($t : cs.Testing.Testing)
    var $expected; $actual : Object
    // ... very deeply nested objects ...
    
    // Increase max depth for very deep structures (default is 10)
    $t.assert.areDeepEqual($t; $expected; $actual; "Deep objects should match"; 20)
```

**Accessing Differences Programmatically:**
When a deep equality assertion fails, the framework stores detailed difference information in `$t.lastDeepEqualDifferences`:

```4d
Function test_with_difference_analysis($t : cs.Testing.Testing)
    var $expected; $actual : Object
    $expected:={name: "John"; age: 30}
    $actual:={name: "John"; age: 25}
    
    $t.assert.areDeepEqual($t; $expected; $actual; "Objects should match")
    
    // If assertion fails, analyze differences
    If ($t.failed)
        var $diff : Object
        For each ($diff; $t.lastDeepEqualDifferences)
            $t.log("Difference at "+$diff.path+": "+$diff.type)
        End for each
    End if
```

**Features:**
- **Recursive Comparison**: Compares nested objects and collections at all levels
- **Detailed Reporting**: Provides path-based difference reporting (e.g., `user.address.city`)
- **Circular Reference Protection**: Max depth limit prevents infinite loops (default: 10 levels)
- **Type Safety**: Detects type mismatches between expected and actual values
- **Missing/Extra Keys**: Reports missing keys in actual object and extra keys not in expected
- **Collection Support**: Handles collections with different lengths and element differences
- **Programmatic Access**: Differences available via `$t.lastDeepEqualDifferences` collection

**Difference Types:**
- `different_value` - Values differ at a specific path
- `missing_key` - Key exists in expected but not in actual
- `extra_key` - Key exists in actual but not in expected
- `different_type` - Types differ between expected and actual
- `different_length` - Collections have different lengths
- `max_depth_exceeded` - Recursion depth limit reached (increase `$maxDepth` if needed)

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
Function test_basic_addition($t : cs.Testing.Testing)
    $t.assert.areEqual($t; 4; 2+2; "Addition should work")

// #tags: integration, slow
Function test_database_connection($t : cs.Testing.Testing)
    // Simulate slow database operation
    DELAY PROCESS(Current process; 10)
    $t.assert.isTrue($t; True; "Database connection test")

// #tags: unit, edge-case
Function test_empty_string_handling($t : cs.Testing.Testing)
    var $result : Text
    $result:=""+"test"
    $t.assert.areEqual($t; "test"; $result; "Empty string concatenation")

// #tags: integration, performance, external
Function test_file_system_access($t : cs.Testing.Testing)
    var $folder : 4D.Folder
    $folder:=Folder(fk desktop folder)
    $t.assert.isNotNull($t; $folder; "Should access desktop folder")
```

### Tag Syntax Rules

- Use `// #tags:` followed by comma-separated tag names
- Tags can contain letters, numbers, hyphens, and underscores
- Whitespace around tags is automatically trimmed
- Tests without explicit tags automatically receive the "unit" tag

### Skipping Tests

Mark a test with the `skip` tag to prevent it from running while still
being reported in the overall test statistics:

```4d
// #tags: unit, skip
Function test_pending_feature($t : cs.Testing.Testing)
    $t.assert.fail($t; "This code is not ready")
```

Skipped tests are counted in the totals and listed separately, but they
do not affect the pass rate.

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
Function test_calculation_logic($t : cs.Testing.Testing)

// #tags: integration
Function test_api_integration($t : cs.Testing.Testing)

// #tags: e2e
Function test_complete_user_workflow($t : cs.Testing.Testing)
```

#### By Speed/Performance
```4d
// #tags: fast
Function test_quick_validation($t : cs.Testing.Testing)

// #tags: slow
Function test_large_dataset_processing($t : cs.Testing.Testing)

// #tags: performance
Function test_response_time_requirements($t : cs.Testing.Testing)
```

#### By Dependencies
```4d
// #tags: database
Function test_user_repository($t : cs.Testing.Testing)

// #tags: external, network
Function test_api_service($t : cs.Testing.Testing)

// #tags: filesystem
Function test_file_operations($t : cs.Testing.Testing)
```

#### By Feature/Component
```4d
// #tags: auth, security
Function test_login_validation($t : cs.Testing.Testing)

// #tags: billing, finance
Function test_payment_processing($t : cs.Testing.Testing)

// #tags: reporting, analytics
Function test_report_generation($t : cs.Testing.Testing)
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

The framework provides built-in mocking capabilities through `$t.stats` (a `UnitStatsTracker` instance):

```4d
Function test_mock_example($t : cs.Testing.Testing)
    // Create a mock object to test
    var $math : Object
    $math:=New object()
    
    // Mock the addNumbers function using Formula
    $math.addNumbers:=Formula($t.stats.mock("addNumbers"; [$1; $2]; 42))
    
    // Call the mocked function
    var $result : Real
    $result:=$math.addNumbers(5; 3)
    
    // Verify the mock was called and returned expected value
    $t.assert.areEqual($t; 42; $result; "Should return mocked value")
    
    // Verify call tracking
    var $stat : cs.UnitStatsDetail
    $stat:=$t.stats.getStat("addNumbers")
    $t.assert.areEqual($t; 1; $stat.getNumberOfCalls(); "Function should be called once")
    $t.assert.areEqual($t; 5; $stat.getXCallYParameter(1; 1); "First parameter should be 5")
    $t.assert.areEqual($t; 3; $stat.getXCallYParameter(1; 2); "Second parameter should be 3")
```

### Advanced Mocking Example

```4d
Function test_multiple_mock_calls($t : cs.Testing.Testing)
    // Create mock service object
    var $service : Object
    $service:=New object()
    
    // Mock the validateUser function
    $service.validateUser:=Formula($t.stats.mock("validateUser"; [$1]; ($1="admin")))
    
    // Make multiple calls with different parameters
    var $adminResult; $guestResult : Boolean
    $adminResult:=$service.validateUser("admin")
    $guestResult:=$service.validateUser("guest")
    
    // Verify results
    $t.assert.isTrue($t; $adminResult; "Admin should be valid")
    $t.assert.isFalse($t; $guestResult; "Guest should be invalid")
    
    // Verify call tracking
    var $stat : cs.UnitStatsDetail
    $stat:=$t.stats.getStat("validateUser")
    
    $t.assert.areEqual($t; 2; $stat.getNumberOfCalls(); "Should be called twice")
    $t.assert.areEqual($t; "admin"; $stat.getXCallYParameter(1; 1); "First call should be admin")
    $t.assert.areEqual($t; "guest"; $stat.getXCallYParameter(2; 1); "Second call should be guest")
```

### ⚠️ **CRITICAL: Avoid `This` in Mock Formulas**

**Rule**: Never use `This` directly inside Formula expressions passed to `$t.stats.mock()`.

When the test runner calls `Formula.apply()` on test methods, it overrides the `This` context for all nested Formulas, causing `This` references to fail.

❌ **Wrong:**
```4d
$object._method:=Formula($t.stats.mock("_method"; Null; This.mockData))
// This.mockData will be undefined due to context override
```

✅ **Correct - Local variable capture:**
```4d
var $mockData : Variant
$mockData:=This.mockData  // Capture the value first
$object._method:=Formula($t.stats.mock("_method"; Null; $mockData))
```

✅ **Alternative - Formula parameters:**
```4d
$object._method:=Formula($t.stats.mock("_method"; Null; $1); This.mockData)
```

**When This Applies:**
- Mock formulas: `Formula($t.stats.mock(...))`
- Any Formula passed to test framework methods
- Any Formula that needs to access test class properties (`This.something`)

**Safe Usage:**
- Local variables and parameters work fine in Formulas
- `This` is safe in the main test method body, just not in nested Formulas
- Test framework objects like `$t.stats` work normally

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
  - **`$t.stats`**: Built-in `UnitStatsTracker` instance for function mocking
- **`cs.TestAssertion`**: Assertion implementation class
- **`cs.UnitStatsTracker`**: Mock tracking implementation class with Formula-based mocking
- **`cs.UnitStatsDetail`**: Detailed call statistics with methods:
  - `.getNumberOfCalls()`: Returns number of times the function was called
  - `.getXCallYParameter(callIndex; paramIndex)`: Returns specific parameter from specific call
  - `.getXCallParams(callIndex)`: Returns parameter collection for specific call
  - `.getXCallParamLength(callIndex)`: Returns parameter count for specific call

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

## Test Lifecycle Methods

The framework supports optional lifecycle methods for test setup and cleanup operations:

### Setup and Teardown (Suite-Level)

These methods run once per test class:

```4d
Class constructor()
    This.testData:=New object

Function setup()
    // Called once BEFORE all tests in this suite
    This.testData.connection:="database_connection"
    This.testData.users:=[]

Function teardown()
    // Called once AFTER all tests in this suite
    This.testData:=Null
```

### BeforeEach and AfterEach (Test-Level)

These methods run before and after each individual test:

```4d
Function beforeEach()
    // Called BEFORE each individual test method
    This.testData.currentTest:="test_"+String(This.beforeEachCount+1)

Function afterEach()
    // Called AFTER each individual test method
    This.testData.currentTest:=""
```

### Complete Example

```4d
Class constructor()
    This.users:=[]
    This.connection:=Null

Function setup()
    // Initialize test environment once
    This.connection:=connectToDatabase()
    This.users:=[]

Function teardown()
    // Cleanup after all tests
    disconnectFromDatabase(This.connection)
    This.connection:=Null

Function beforeEach()
    // Reset state before each test
    This.users:=[]
    createTestUser("testuser@example.com")

Function afterEach()
    // Cleanup after each test
    clearTestData()

Function test_user_creation($t : cs.Testing.Testing)
    // Test uses clean state from beforeEach
    $t.assert.areEqual($t; 1; This.users.length; "Should have one test user")

Function test_user_validation($t : cs.Testing.Testing)
    // Also gets clean state from beforeEach
    var $user : Object
    $user:=This.users[0]
    $t.assert.areEqual($t; "testuser@example.com"; $user.email; "User email should be correct")
```

### Execution Order

For each test class, the framework executes lifecycle methods in this order:

1. **Class constructor** - Creates the test instance
2. **setup()** - One-time setup for the entire suite
3. For each test method:
   - **beforeEach()** - Pre-test setup
   - **test_xxx()** - The actual test
   - **afterEach()** - Post-test cleanup
4. **teardown()** - One-time cleanup for the entire suite

### Best Practices

- **Use `setup()` for expensive operations** that can be shared across tests (database connections, file loading)
- **Use `beforeEach()` for test isolation** to ensure each test starts with clean state
- **Use `afterEach()` for immediate cleanup** to prevent tests from affecting each other
- **Use `teardown()` for final cleanup** to release resources and reset global state
- **Keep lifecycle methods lightweight** to minimize test execution overhead
- **Handle errors gracefully** in cleanup methods to prevent test failures from masking real issues

## Table-Driven Tests

Use subtests to implement table-driven tests. The `t.run` method executes a named subtest with a fresh testing context. If a subtest fails, the parent test is marked as failed and the subtest's log messages are prefixed with its name. Subtests share the same `This` object as the parent test, so any instance methods or state remain available. Pass optional data as the third argument when using a helper method for the subtest logic.

```4d
Function test_math_operations($t : cs.Testing.Testing)
    var $cases : Collection
    $cases:=[New object("name"; "1+1"; "in"; 1; "want"; 2)]

    var $case : Object
    For each ($case; $cases)
        $t.run($case.name; This._checkMathCase; $case)
    End for each

Function _checkMathCase($t : cs.Testing.Testing; $case : Object)
    $t.assert.areEqual($t; $case.want; $case.in+1; "math works")
```

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
Function test_withTransactions($t : cs.Testing.Testing)
    // Automatic transactions enabled (default)
    // Test data changes will be rolled back
    
Function test_withoutTransactions($t : cs.Testing.Testing)  
    // #transaction: false
    // Disables automatic transaction management
```

### Manual Transaction Control

The Testing context provides methods for manual transaction management:

```4d
    // #transaction: false
Function test_manualTransactions($t : cs.Testing.Testing)
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

    // #transaction: false
Function test_transactionWrapper($t : cs.Testing.Testing)
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

### Transaction Management Methods

The `$t` (Testing) context provides these transaction management methods:

- `$t.startTransaction()` - Begins a new transaction manually
- `$t.validateTransaction()` - Commits the current transaction
- `$t.cancelTransaction()` - Rolls back the current transaction
- `$t.inTransaction()` - Returns true if currently in a transaction
- `$t.withTransaction(formula)` - Executes formula in transaction with automatic rollback
- `$t.withTransactionValidate(formula)` - Executes formula in transaction with commit on success

### Best Practices

- Use automatic transactions (default) for most unit tests to ensure isolation
- Disable transactions (`// #transaction: false`) only when testing transaction-related functionality
- Use manual transaction control for integration tests that need to verify data persistence
- Always check `$t.inTransaction()` before performing transaction operations
- Use `withTransaction()` for operations that should always rollback
- Use `withTransactionValidate()` for operations that should persist on test success

## License

MIT License - see LICENSE file for details.
