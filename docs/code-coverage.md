# Code Coverage for 4D Unit Testing Framework

This document provides detailed information about the code coverage functionality in the 4D Unit Testing Framework.

## Overview

Code coverage measures which lines of code are executed during test runs. This helps identify untested code and improve test quality.

The framework uses 4D's `METHOD GET CODE` and `METHOD SET CODE` commands to instrument code at runtime, track execution, and generate comprehensive coverage reports.

## Architecture

### Core Components

1. **CoverageTracker** - Tracks which lines are executed during tests
   - Uses shared Storage for thread-safe tracking across parallel test execution
   - Records coverage data per method and line number
   - Calculates coverage statistics

2. **CodeInstrumenter** - Modifies code to inject tracking calls
   - Gets original code using `METHOD GET CODE`
   - Identifies executable lines (skips comments, declarations, etc.)
   - Injects tracking calls after each executable line
   - Sets instrumented code using `METHOD SET CODE`
   - Restores original code after tests complete

3. **CoverageReporter** - Generates coverage reports
   - Calculates line-level coverage statistics
   - Supports multiple output formats (text, JSON, LCOV)
   - Identifies uncovered lines for targeted test improvements

### How Instrumentation Works

When coverage is enabled, the instrumenter:

1. **Retrieves** the original source code for each method
2. **Parses** the code to identify executable lines
3. **Injects** tracking calls using this pattern:
   ```4d
   If (Storage.coverage#Null) : Use (Storage.coverage) : 
       If (Storage.coverage.data["MethodName"]=Null) : 
           Storage.coverage.data["MethodName"]:=New shared object("lines"; New shared collection) : 
       End if : 
       Use (Storage.coverage.data["MethodName"]) : 
           If (Storage.coverage.data["MethodName"].lines.indexOf(lineNumber)=-1) : 
               Storage.coverage.data["MethodName"].lines.push(lineNumber) : 
           End if : 
       End use : 
   End use : End if
   ```
4. **Applies** the instrumented code to the method
5. **Runs** tests with the instrumented code
6. **Collects** coverage data from Storage
7. **Restores** original code after tests complete

### What Gets Instrumented

**Included:**
- All classes in the host project (from the `cs` class store)
- Project methods in the host project

**Excluded:**
- Test classes (classes ending with "Test")
- Testing framework classes (TestRunner, Assert, Testing, etc.)
- Internal test classes (classes starting with "_")
- DataClasses and Entity classes

### Executable Line Detection

The instrumenter identifies executable lines by excluding:
- Empty lines
- Comment lines (`// ...`)
- Property declarations (`property x : Type`)
- Class constructor signatures
- Function signatures
- Control flow end statements (`End if`, `End case`, `End for`, etc.)
- Else clauses

## Usage

### Basic Usage

```bash
# Enable coverage with text report
make test-coverage

# Or manually:
tool4d --project YourProject.4DProject --startup-method "test" --user-param "coverage=true"
```

### Configuration Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `coverage` | `true`, `enabled` | (disabled) | Enable coverage tracking |
| `coverageFormat` | `text`, `json`, `lcov` | `text` | Output format |
| `coverageOutput` | file path | (console) | Write report to file |

### Output Formats

#### Text Format (Human-Readable)

Displays coverage summary and per-method statistics with uncovered line numbers:

```
=== Code Coverage Report ===

Overall Coverage: 85.5% (234/274 lines)

Method Coverage:
  OrderService.calculate: 100% (45/45 lines)
  OrderService.validate: 75% (18/24 lines)
    Uncovered lines: 67, 89, 102
  PaymentProcessor.process: 90% (27/30 lines)
    Uncovered lines: 156, 201, 245
```

#### JSON Format (Machine-Readable)

Structured data for programmatic processing:

```json
{
  "summary": {
    "totalLines": 274,
    "coveredLines": 234,
    "uncoveredLines": 40,
    "coveragePercent": 85.5
  },
  "methods": [
    {
      "method": "OrderService.calculate",
      "totalLines": 45,
      "coveredLines": 45,
      "uncoveredLines": 0,
      "coveragePercent": 100,
      "coveredLineNumbers": [10, 11, 12, 15, 16, ...],
      "executableLines": [10, 11, 12, 15, 16, ...]
    },
    {
      "method": "OrderService.validate",
      "totalLines": 24,
      "coveredLines": 18,
      "uncoveredLines": 6,
      "coveragePercent": 75,
      "coveredLineNumbers": [10, 11, 15, ...],
      "executableLines": [10, 11, 15, 67, 89, 102, ...]
    }
  ]
}
```

#### LCOV Format (CI/CD Integration)

Standard format compatible with GitLab, SonarQube, and other tools:

```
TN:
SF:testing/Project/Sources/Classes/OrderService.4dm
DA:10,1
DA:11,1
DA:12,1
DA:67,0
DA:89,0
LF:24
LH:18
end_of_record
```

### Make Targets

```bash
# Run tests with coverage (text report to console)
make test-coverage

# Run tests with coverage (JSON report to console)
make test-coverage-json

# Run tests with coverage (LCOV report to file)
make test-coverage-lcov

# Run unit tests with coverage
make test-coverage-unit

# Custom coverage with parameters
make test coverage=true coverageFormat=json tags=integration
```

## Integration with CI/CD

### GitLab CI Example

```yaml
test:
  script:
    - make test-coverage-lcov
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/lcov.info
  coverage: '/Overall Coverage: (\d+\.?\d*)%/'
```

### GitHub Actions Example

```yaml
- name: Run tests with coverage
  run: make test-coverage-json > coverage.json

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage.json
```

## Best Practices

### 1. Run Coverage Regularly

Integrate coverage into your development workflow:
- Run locally before committing
- Include in CI/CD pipeline
- Track coverage trends over time

### 2. Set Coverage Goals

Establish coverage targets based on code criticality:
- Critical business logic: 90%+ coverage
- Standard features: 80%+ coverage
- Edge cases and error handling: 70%+ coverage

### 3. Focus on Gaps

Use uncovered line numbers to:
- Identify missing test cases
- Find error handling paths not tested
- Discover edge cases

### 4. Combine with Test Filtering

Target specific areas for coverage improvement:

```bash
# Coverage for business logic only
make test coverage=true tags=business-logic

# Coverage for database layer
make test coverage=true tags=database

# Coverage excluding slow tests
make test coverage=true excludeTags=slow
```

### 5. Write Tests for Coverage Gaps

When coverage reports show uncovered lines:

1. **Examine the code** - Understand why lines are uncovered
2. **Write targeted tests** - Focus on specific scenarios
3. **Run coverage again** - Verify improvement
4. **Refactor if needed** - Sometimes uncovered code indicates dead code

### Example Workflow

```bash
# 1. Run tests with coverage
make test-coverage-json > coverage.json

# 2. Review JSON report to find gaps
cat coverage.json | jq '.methods[] | select(.coveragePercent < 80)'

# 3. Write tests for uncovered code
# (Edit test files)

# 4. Verify improvement
make test-coverage
```

## Performance Considerations

### Instrumentation Overhead

Code instrumentation adds overhead:
- **Startup time**: +2-5 seconds for instrumentation
- **Execution time**: +10-20% for tracking calls
- **Memory usage**: Minimal (tracking data stored in shared collections)

### Optimization Tips

1. **Use with test filtering** - Only instrument code under test
2. **Run selectively** - Don't run coverage on every test run
3. **Cache coverage results** - Generate once, analyze multiple times

## Limitations

### Current Limitations

1. **Line-level coverage only** - No branch coverage or path coverage
2. **Class methods only** - Project methods in Methods folder not yet supported
3. **No partial line coverage** - Multi-statement lines counted as single unit
4. **Compiled code** - Works best with interpreted code

### Known Issues

1. **Complex expressions** - Very long lines may not track accurately
2. **Dynamic code** - Code generated at runtime not tracked
3. **External calls** - Calls to 4D commands or components not tracked

## Troubleshooting

### Coverage is 0%

**Problem**: Coverage shows 0% even though tests run

**Solutions**:
- Ensure `coverage=true` parameter is set
- Check that instrumented methods are actually called during tests
- Verify Storage is accessible (not blocked by security settings)

### Methods Not Instrumented

**Problem**: Some methods don't appear in coverage report

**Solutions**:
- Check if methods are in excluded categories (test classes, framework classes)
- Verify METHOD GET CODE returns code for the method
- Ensure method is in the host project, not a component

### Coverage Report Missing

**Problem**: Tests run but no coverage report generated

**Solutions**:
- Check console output for instrumentation messages
- Verify coverageOutput path is writable
- Ensure coverage tracking completed before report generation

### Instrumentation Errors

**Problem**: Errors during code instrumentation

**Solutions**:
- Verify METHOD SET CODE is allowed (not in production mode)
- Check method syntax is valid
- Review 4D version compatibility

## Technical Details

### Storage Structure

Coverage data is stored in `Storage.coverage`:

```4d
Storage.coverage := {
    data: {
        "ClassName.methodName": {
            lines: [10, 11, 15, 20, ...]  // Covered line numbers
        },
        "OtherClass.method": {
            lines: [5, 8, 12, ...]
        }
    }
}
```

### Thread Safety

- Uses shared objects and collections
- `Use...End use` blocks for synchronization
- Safe for parallel test execution

### Cleanup

Coverage system automatically:
- Clears tracking data before each run
- Restores original code after tests
- Releases shared storage resources

## Examples

### Example 1: Basic Coverage

```bash
# Run all tests with coverage
make test-coverage
```

Output:
```
Instrumenting code for coverage tracking...
Instrumented 45 methods

=== 4D Unit Testing Framework ===
Running tests...

  ✓ test_order_creation (2ms)
  ✓ test_order_validation (3ms)
  ✓ test_payment_processing (5ms)

=== Test Results Summary ===
Total Tests: 3
Passed: 3
Failed: 0

=== Code Coverage Report ===

Overall Coverage: 87.5% (175/200 lines)

Method Coverage:
  OrderService.create: 100% (25/25 lines)
  OrderService.validate: 85% (34/40 lines)
    Uncovered lines: 67, 89, 102, 145, 201, 234
```

### Example 2: Coverage with JSON

```bash
# Run tests with JSON coverage report
make test-coverage-json > coverage.json

# Parse with jq
cat coverage.json | jq '.summary'
```

Output:
```json
{
  "totalLines": 200,
  "coveredLines": 175,
  "uncoveredLines": 25,
  "coveragePercent": 87.5
}
```

### Example 3: Coverage for Specific Tests

```bash
# Coverage for unit tests only
make test coverage=true tags=unit coverageFormat=json
```

### Example 4: LCOV for CI/CD

```bash
# Generate LCOV report
make test-coverage-lcov

# Output file
cat coverage/lcov.info
```

## API Reference

### CoverageTracker

```4d
// Create tracker
$tracker := cs.CoverageTracker.new()

// Enable tracking
$tracker.enable()

// Track line execution (called by instrumented code)
$tracker.track("ClassName.methodName"; lineNumber)

// Disable tracking
$tracker.disable()

// Collect results
$results := $tracker.collectResults()

// Get stats
$stats := $tracker.getStats()

// Clear data
$tracker.clear()
```

### CodeInstrumenter

```4d
// Create instrumenter
$instrumenter := cs.CodeInstrumenter.new(cs; $tracker)

// Instrument single method
$success := $instrumenter.instrumentMethod("ClassName.methodName")

// Instrument entire class
$count := $instrumenter.instrumentClass("ClassName")

// Instrument all host classes
$count := $instrumenter.instrumentAllHostClasses()

// Restore original code
$instrumenter.restoreAll()
```

### CoverageReporter

```4d
// Create reporter
$reporter := cs.CoverageReporter.new($tracker; $instrumenter)

// Calculate coverage
$report := $reporter.calculateCoverage()

// Generate reports
$textReport := $reporter.generateTextReport()
$jsonReport := $reporter.generateJSONReport()
$lcovReport := $reporter.generateLCOVReport()

// Write to file
$reporter.writeReportToFile("lcov"; "coverage/lcov.info")

// Log to console
$reporter.logToConsole()
```

## Future Enhancements

Potential improvements for future versions:

1. **Branch coverage** - Track which branches (if/else) are taken
2. **Function coverage** - Track which functions are called
3. **Path coverage** - Track execution paths through code
4. **HTML reports** - Visual coverage reports with highlighted code
5. **Coverage thresholds** - Fail tests if coverage below threshold
6. **Incremental coverage** - Track coverage changes between runs
7. **Method-level filtering** - Include/exclude specific methods from coverage
8. **Project method support** - Full support for Methods folder

## Contributing

To improve coverage functionality:

1. Report issues with instrumentation
2. Suggest new report formats
3. Contribute example integrations
4. Improve documentation

## License

Code coverage functionality is part of the 4D Unit Testing Framework and is licensed under the MIT License.
