# 4D Testing Framework Guide for AI Agents

## Quick Start

1. **Test Class Pattern**: Create classes ending with "Test" (e.g., `MyFeatureTest.4dm`)
2. **Test Methods**: Methods starting with "test_" are auto-discovered
3. **Required Parameter**: All test methods must accept `$t : cs:C1710.Testing`

## Basic Test Structure

```4d
Class constructor()

// #tags: unit, fast
Function test_example($t : cs:C1710.Testing)
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
- Built-in assertions via `$t.assert` 
- Built-in statistics via `$t.stats`
- Logging via `$t.log("message")`
- Failure marking via `$t.fail()` and `$t.fatal()`

## Running Tests

```bash
# All tests (human output)
tool4d --project path/to/project.4DProject --startup-method "test"

# JSON output for CI/CD
tool4d --project path/to/project.4DProject --startup-method "test" --user-param "format=json"

# Filter by tags
--user-param "tags=unit"
--user-param "excludeTags=slow" 
--user-param "requireTags=fast,unit"

# Filter by name
--user-param "test=MyTestClass"
```

## Best Practices

1. **Test behavior, not implementation** - Focus on what the code does, not how it does it
2. **One assertion per test** when possible
3. **Descriptive test names** using underscores: `test_user_login_with_invalid_password`  
4. **Clear failure messages** explaining what went wrong
5. **Tag appropriately** - use `unit` for isolated tests, `integration` for database/external dependencies
6. **Keep tests fast** - tag slow tests and run separately if needed

## Test Discovery Rules

- Classes ending in "Test" are discovered automatically
- Methods starting with "test_" are executed as tests
- Tests run in alphabetical order by class name, then method name
- Framework reports total tests, passes, failures, and execution time