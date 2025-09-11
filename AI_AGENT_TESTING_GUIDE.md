# 4D Testing Framework Guide for AI Agents

## Quick Start

1. **Test Class Pattern**: Create classes ending with "Test" (e.g., `MyFeatureTest.4dm`)
2. **Test Methods**: Methods starting with "test_" are auto-discovered
3. **Required Parameter**: All test methods must accept `$t : cs.Testing.Testing`

## Basic Test Structure

```4d
Class constructor()

// #tags: unit, fast
Function test_example($t : cs.Testing.Testing)
    $t.assert.areEqual($t; expected; actual; "Description")
```

## Essential Assertions

The `$t.assert` object provides these methods:

```4d
$t.assert.areEqual($t; expected; actual; "message")
$t.assert.isTrue($t; condition; "message")  
$t.assert.isFalse($t; condition; "message")
$t.assert.isNull($t; value; "message")
$t.assert.isNotNull($t; value; "message")
$t.assert.contains($t; container; value; "message")  // For text and collections
$t.assert.fail($t; "explicit failure message")
```

## Test Tagging System

Tag tests with comments above function declarations:

```4d
// #tags: unit, fast           // Quick unit tests
// #tags: integration, slow    // Database/external tests  
// #tags: performance         // Performance benchmarks
// #tags: edge-case           // Edge case scenarios
// #tags: validation          // Input validation tests
```

## Testing Context (`$t`)

The Testing object provides:
- **Assertions**: `$t.assert` for test validations
- **Mocking/Spying**: `$t.stats` for tracking function calls
- **Logging**: `$t.log("message")` for test output
- **Control**: `$t.fail()` and `$t.fatal()` for explicit failures
- **Subtests**: `$t.run("name", methodRef, data)` for data-driven testing
- **Transactions**: Manual database transaction control

## Mocking and Spying (`$t.stats`)

The stats system enables method replacement mocking:

```4d
Function test_with_mocking($t : cs.Testing.Testing)
    var $service : cs:C1710.EmailService
    $service := cs:C1710.EmailService.new()
    
    // Mock the sendEmail method
    $service.sendEmail := Formula($t.stats.mock("sendEmail"; [$1; $2]; True))
    
    // Code under test calls $service.sendEmail()
    var $result : Boolean
    $result := $service.processOrder($order)
    
    // Verify interaction
    $t.assert.areEqual($t; 1; $t.stats.getStat("sendEmail").getNumberOfCalls(); "Should send one email")
    
    // Check parameters passed to mock
    var $callParams : Collection
    $callParams := $t.stats.getStat("sendEmail").getXCallParams(1)
    $t.assert.areEqual($t; "user@example.com"; $callParams[0]; "Should email correct recipient")
```

**Mock Methods:**
- `$t.stats.mock("name"; [params]; returnValue)` - Create mock response
- `$t.stats.getStat("name").getNumberOfCalls()` - Get call count
- `$t.stats.getStat("name").getXCallParams(N)` - Get Nth call parameters
- `$t.stats.getStat("name").getXCallYParameter(N, M)` - Get specific parameter
- `$t.stats.resetStatistics()` - Reset all mock tracking

### ⚠️ **CRITICAL: Avoid `This` in Mock Formulas**

**Rule**: Never use `This` directly inside Formula expressions passed to `$t.stats.mock()`.

When the test runner calls `Formula.apply()` on test methods, it overrides the `This` context for all nested Formulas, causing `This` references to fail.

❌ **Wrong:**
```4d
$object._method:=Formula($t.stats.mock("_method"; Null; This.mockData))
// This.mockData will be undefined
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

## Subtests and Data-Driven Testing

Use subtests for data-driven testing with multiple test cases:

```4d
Class constructor()
    This.testCases:=[\
        {name: "Valid Email"; input: "user@domain.com"; expected: True}; \
        {name: "Invalid Email"; input: "invalid-email"; expected: False}; \
        {name: "Empty String"; input: ""; expected: False}\
    ]

Function test_email_validation($t : cs.Testing.Testing)
    var $testCase : Object
    For each ($testCase; This.testCases)
        $t.run($testCase.name; This._email_validation_case; $testCase)
    End for each 

Function _email_validation_case($t : cs.Testing.Testing; $case : Object)
    var $validator : cs:C1710.EmailValidator
    $validator := cs:C1710.EmailValidator.new()
    
    var $result : Boolean
    $result := $validator.isValid($case.input)
    
    $t.assert.areEqual($t; $case.expected; $result; "Email validation should match expected result")
```

**Benefits of this pattern:**
- Clean separation of test data and test logic
- Reusable test case methods
- Easy to add new test cases
- Better debugging and maintenance

## Transaction Management

**Automatic Transactions (Default):**
Tests run in transactions that auto-rollback for isolation.

**Manual Transaction Control:**
```4d
// #tags: integration
// #transaction: false  // Disable automatic transactions
Function test_manual_transactions($t : cs.Testing.Testing)
    $t.startTransaction()
    
    // Database operations
    If ($success)
        $t.validateTransaction()
    Else 
        $t.cancelTransaction()
    End if
    
    // Or use wrapper methods
    $success := $t.withTransaction(Formula(
        // Operations here auto-rollback
    ))
    
    $success := $t.withTransactionValidate(Formula(
        // Operations here persist on success
    ))
```

**Transaction Methods:**
- `$t.startTransaction()` - Begin transaction
- `$t.validateTransaction()` - Commit transaction  
- `$t.cancelTransaction()` - Rollback transaction
- `$t.inTransaction()` - Check transaction status
- `$t.withTransaction(Formula)` - Execute with auto-rollback
- `$t.withTransactionValidate(Formula)` - Execute with auto-commit

## Running Tests

### Using Makefile (Recommended)
```bash
# Basic test runs
make test                    # All tests, human output
make test-json              # All tests, JSON output
make test-junit             # All tests, JUnit XML output

# Filtering
make test tags=unit         # Only unit tests
make test tags=integration  # Only integration tests  
make test-exclude-tags TAGS=slow  # Exclude slow tests
make test-class CLASS=MyTest     # Specific test class

# Parallel execution
make test-parallel          # Run tests in parallel
make test-parallel-workers WORKERS=4  # Custom worker count

# CI/CD
make test-ci               # Generate JUnit XML for CI/CD
```

### Manual Execution
```bash
# All tests (human output)
tool4d --project path/to/project.4DProject --startup-method "test"

# JSON output for CI/CD
tool4d --project path/to/project.4DProject --startup-method "test" --user-param "format=json"

# JUnit XML output
tool4d --project path/to/project.4DProject --startup-method "test" --user-param "format=junit"

# Verbose JSON with full details
tool4d --project path/to/project.4DProject --startup-method "test" --user-param "format=json verbose=true"
```

## Advanced Filtering

### Tag-Based Filtering
```bash
# Include tags (OR logic)
--user-param "tags=unit,integration"

# Exclude tags  
--user-param "excludeTags=slow,external"

# Require all tags (AND logic)
--user-param "requireTags=unit,fast"

# Combined filtering
--user-param "tags=unit excludeTags=slow"
```

### Name-Based Filtering
```bash
# Specific test class
--user-param "test=MyTestClass"

# Multiple classes
--user-param "test=UserTest,OrderTest"

# Pattern matching
--user-param "test=*ValidationTest"
```

### Parallel Execution
```bash
# Enable parallel execution
--user-param "parallel=true"

# Custom worker count
--user-param "parallel=true maxWorkers=4"

# Opt out of parallel execution (in test class)
// #parallel: false
```

## Output Formats

### Human Format (Default)
- Real-time progress with ✓/✗ indicators
- Individual test timing
- Detailed error messages with call stacks
- Summary with pass rates and totals

### JSON Terse (Default JSON)
```json
{
  "tests": 121,
  "passed": 121, 
  "failed": 0,
  "rate": 100.0,
  "duration": 1234,
  "status": "ok"
}
```

### JSON Verbose
```json
{
  "totalTests": 121,
  "passed": 121,
  "failed": 0,
  "suites": [...],
  "failedTests": [...],
  "passRate": 100.0,
  "status": "success"
}
```

### JUnit XML
Compatible with GitLab CI/CD, Jenkins, and other CI systems:
```bash
--user-param "format=junit outputPath=custom/path/results.xml"
```

## Best Practices

1. **Test behavior, not implementation** - Focus on what the code does, not how it does it
2. **One assertion per test** when possible
3. **Descriptive test names** using underscores: `test_user_login_with_invalid_password`  
4. **Clear failure messages** explaining what went wrong
5. **Tag appropriately** - use `unit` for isolated tests, `integration` for database/external dependencies
6. **Mock dependencies** - Use `$t.stats` to isolate units under test
7. **Keep tests fast** - tag slow tests and run separately if needed
8. **Use transactions wisely** - Default auto-rollback for most tests, manual control when needed
9. **Data-driven testing** - Use subtests with class methods for multiple test cases

## Test Discovery Rules

- Classes ending in "Test" are discovered automatically
- Methods starting with "test_" are executed as tests
- Tests run in alphabetical order by class name, then method name
- Framework supports lifecycle methods: `setup()`, `teardown()`, `beforeEach()`, `afterEach()`
- Framework reports total tests, passes, failures, and execution time

## Lifecycle Methods

```4d
Function setup()
    // Called ONCE before all tests in the suite
    This.sharedData := New object("connection"; "test_db")

Function teardown()
    // Called ONCE after all tests in the suite
    This.sharedData := Null

Function beforeEach()
    // Called before EACH individual test method
    This.currentTestName := Current method name

Function afterEach()
    // Called after EACH individual test method
    // Cleanup after each test
```
