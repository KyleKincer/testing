# 4D Unit Testing Framework

A comprehensive unit testing framework for the 4D platform with test tagging, filtering, and CI/CD integration.

## Key Features

- **Auto test discovery** - Finds test classes ending with "Test"
- **Test tagging** - Organize tests with `// #tags: unit, integration, slow`
- **Flexible filtering** - Run specific tests by name, pattern, or tags
- **Multiple output formats** - Human-readable and JSON output
- **CI/CD ready** - Structured JSON output for automated testing
- **Transaction management** - Automatic test isolation with rollback
- **Subtests** - Run table-driven tests with `t.run`

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

# Run specific tests
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=UserServiceTest"
tool4d --project YourProject.4DProject --startup-method "test" --user-param "test=UserServiceTest.test_user_creation"

# Filter by tags
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit"
tool4d --project YourProject.4DProject --startup-method "test" --user-param "tags=unit excludeTags=slow"
```

## Code Coverage

The framework supports code coverage tracking to measure which lines of your code are executed during tests. Coverage uses runtime instrumentation to track execution without requiring external tools.

### Enabling Coverage

```bash
# Enable coverage with default settings (text output to console)
tool4d --project YourProject.4DProject --startup-method "test" --user-param "coverage=true"

# Generate HTML coverage report
tool4d --project YourProject.4DProject --startup-method "test" --user-param "coverage=true coverageFormat=html coverageOutput=coverage/report.html"

# Generate lcov format for CI/CD integration
tool4d --project YourProject.4DProject --startup-method "test" --user-param "coverage=true coverageFormat=lcov coverageOutput=coverage/lcov.info"

# Combined with test filtering
tool4d --project YourProject.4DProject --startup-method "test" --user-param "coverage=true tags=unit coverageFormat=html coverageOutput=coverage/unit.html"
```

### Coverage Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `coverage` | `true`, `enabled` | Enable code coverage tracking |
| `coverageFormat` | `text`, `json`, `html`, `lcov` | Report format (default: `text`) |
| `coverageOutput` | File path | Write report to file instead of console |
| `coverageMethods` | Comma-separated patterns | Specific methods to track (default: auto-discover) |

### Coverage Report Formats

#### Text Format
Human-readable console output showing coverage statistics:
```
=== Code Coverage Report ===

Overall Coverage: 85.50%
Lines Covered: 342 / 400
Methods Tracked: 25

=== Method Coverage ===

UserService.validateEmail
  [==================  ] 95.00% (19/20 lines)
  Uncovered lines: 15

OrderProcessor.calculateTotal
  [===============     ] 75.00% (30/40 lines)
  Uncovered lines: 5-8, 12, 18-20
```

#### JSON Format
Structured data for programmatic consumption:
```json
{
  "summary": {
    "totalLines": 400,
    "coveredLines": 342,
    "uncoveredLines": 58,
    "coveragePercent": 85.5,
    "methodCount": 25
  },
  "methods": [
    {
      "method": "UserService.validateEmail",
      "totalLines": 20,
      "coveredLines": 19,
      "coveragePercent": 95.0,
      "uncoveredLines": [15]
    }
  ]
}
```

#### HTML Format
Interactive visual report with color-coded coverage levels:
- **Green (≥90%)**: Excellent coverage
- **Yellow (≥75%)**: Good coverage
- **Orange (≥50%)**: Moderate coverage
- **Red (<50%)**: Poor coverage

#### LCOV Format
Industry-standard format compatible with:
- GitLab CI/CD coverage visualization
- SonarQube
- Codecov
- Coveralls
- Most CI/CD platforms

### How Coverage Works

The framework instruments your code by:
1. **Discovery**: Identifies methods to track (excluding test methods)
2. **Instrumentation**: Injects execution counters using `METHOD GET CODE` and `METHOD SET CODE`
3. **Execution**: Runs tests and collects line execution data
4. **Restoration**: Restores original code after tests complete
5. **Reporting**: Generates coverage reports in requested format

### Best Practices

1. **Focus on Business Logic**: Coverage automatically excludes test methods
2. **Use with CI/CD**: Generate lcov reports for pipeline integration
3. **Set Coverage Goals**: Aim for 80%+ coverage on critical paths
4. **Review Uncovered Lines**: Check if missing coverage indicates untested edge cases
5. **Combine with Tests**: Run `tags=unit` for unit test coverage, `tags=integration` for integration coverage

### Example: CI/CD Integration

```yaml
# .gitlab-ci.yml
test:
  script:
    - tool4d --project MyProject.4DProject --startup-method "test" --user-param "coverage=true coverageFormat=lcov coverageOutput=coverage/lcov.info"
  coverage: '/Overall Coverage: (\d+\.?\d*)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/lcov.info
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

**JSON format:**
```json
{
  "totalTests": 2,
  "passed": 2,
  "failed": 0,
  "passRate": 100,
  "status": "success"
}
```

## Documentation

- [Detailed Guide](docs/guide.md) - Complete documentation with examples
- [Code Coverage Guide](docs/coverage-guide.md) - Comprehensive coverage documentation
- [CI/CD Integration](docs/guide.md#cicd-integration)
- [Advanced Features](docs/guide.md#test-tagging)

## License

MIT License
