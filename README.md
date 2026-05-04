# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D platform with test tagging, filtering, and CI/CD integration.

## Key Features

- **Auto test discovery** - Finds test classes ending with "Test"
- **Test tagging** - Organize tests with `// #tags: unit, integration, slow`
- **Flexible filtering** - Run specific tests by name, pattern, or tags
- **Multiple output formats** - Human-readable, JSON, and JUnit XML
- **CI/CD ready** - Structured JSON / JUnit XML output for automated testing
- **Transaction management** - Automatic test isolation with rollback
- **Subtests** - Run table-driven tests with `t.run`
- **Host runtime-error capture** - When used as a component, captures and reports
  host-side runtime errors (per-test and global) with stack chains

## Quick Example

```4d
// UserServiceTest.4dm
Class constructor()

// #tags: unit, fast
Function test_user_creation($t : cs.Testing)
    var $user : Object
    $user:=New object("name"; "John"; "email"; "john@example.com")
    
    $t.assert.isNotNull($t; $user.name; "User should have a name")
    $t.assert.areEqual($t; "John"; $user.name; "User name should be correct")
    
    // Compare complex objects with deep equality
    var $expected : Object
    $expected:=New object("name"; "John"; "email"; "john@example.com")
    $t.assert.areDeepEqual($t; $expected; $user; "User object should match expected structure")

// #tags: integration, database
Function test_user_persistence($t : cs.Testing)
    // Database operations are automatically rolled back
    var $user : cs.UsersEntity
    $user:=ds.Users.new()
    $user.name:="John"
    $user.email:="john@example.com"
    var $result : Object
    $result:=$user.save()
    $t.assert.isTrue($t; $result.success; "User should be saved successfully")
```

## Setup

Create a project method (e.g., "test") with this code:

```4d
var $runner : cs.Testing.TestRunner
$runner:=cs.Testing.TestRunner.new(cs)
$runner.run()
```

## Running Tests

```bash
# Run all tests
tool4d --project YourProject.4DProject --startup-method "test"

# Run with JSON output
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json"

# Write JSON to a file (clean output, even with debug logs on stdout)
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json outputPath=test-results/report.json"

# Include call chains on failed tests in terse JSON without going full verbose
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=json callchain=true"

# JUnit XML output (CI-friendly: failures, errors, skipped, system-err)
tool4d --project YourProject.4DProject --startup-method "test" --user-param "format=junit outputPath=test-results/junit.xml"

# Run specific tests
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=UserServiceTest"
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=UserServiceTest.test_user_creation"

# Filter by tags
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit"
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit excludeTags=slow"
```

## Table-Driven Tests

Use subtests to build table-driven tests. Each call to `t.run` executes the provided function with a fresh testing context. If a subtest fails, the parent test is marked as failed. Subtests run with the same `This` object as the parent test, so helper methods and state remain accessible. Pass optional data as the third argument when the test logic lives in a separate method.

```4d
Function test_math($t : cs.Testing)
    var $cases : Collection
    $cases:=[New object("name"; "1+1"; "in"; 1; "want"; 2)]

    var $case : Object
    For each ($case; $cases)
        $t.run($case.name; This._checkMathCase; $case)
    End for each

Function _checkMathCase($t : cs.Testing; $case : Object)
    $t.assert.areEqual($t; $case.want; $case.in+1; "math works")
```

## Output

**Human format:**
```
  ✓ test_user_creation (1ms)
  ✓ test_user_persistence (5ms)

2 tests passed
```

**JSON format (terse — default with `format=json`):**
```json
{
  "tests": 2,
  "passed": 2,
  "failed": 0,
  "skipped": 0,
  "duration": 6,
  "rate": 100.0,
  "status": "ok",
  "globalErrorCount": 0,
  "globalErrors": [],
  "testResults": [ /* per-test entries with assertions[] and runtimeErrors[] */ ],
  "failures": [ /* one entry per failed test, includes callChain when verbose=true or callchain=true */ ]
}
```

External (non-test) runtime errors captured during the run live in
`globalErrors[]` / `globalErrorCount`. JUnit output reports the same data in a
`<system-err>` block.

## Capturing Host Runtime Errors

When the testing framework is loaded as a component into a host project, host-side
code (triggers, workers, methods called by tests) can raise runtime errors that
the component's own `ON ERR CALL` cannot reach. To capture them:

1. Define `TestErrorHandler` and `TestGlobalErrorHandler` project methods in the
   host that push `{code, text, method, line, message, processNumber, context,
   isLocal, callChainJSON, ...}` records onto `Storage.testErrors` (a shared
   collection).
2. In the host's test entry point, install both handlers and pass the host's
   `Storage` to the component:

   ```4d
   // RunTests.4dm
   ON ERR CALL("TestErrorHandler")
   ON ERR CALL("TestGlobalErrorHandler"; 1)
   Testing_RunTestsWithCs(cs; Storage; $userParams)
   ```

3. The component drains `Storage.testErrors` per-test (matched by
   `processNumber`) and globally, and surfaces them in every output format:
   per-test `runtimeErrors[]` in JSON, top-level `globalErrors[]`, and JUnit
   `<system-err>`.

## Documentation

- [Detailed Guide](docs/guide.md) - Complete documentation with examples
- [CI/CD Integration](docs/guide.md#cicd-integration)
- [Advanced Features](docs/guide.md#test-tagging)

## License

MIT License
