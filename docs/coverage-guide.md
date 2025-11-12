# Code Coverage Guide

This guide provides comprehensive documentation for using code coverage with the 4D Unit Testing Framework.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Configuration](#configuration)
- [Report Formats](#report-formats)
- [Best Practices](#best-practices)
- [Advanced Usage](#advanced-usage)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Overview

Code coverage measures which lines of your code are executed during test runs. The 4D Unit Testing Framework provides built-in coverage tracking using runtime code instrumentation.

### Key Features

- **No External Tools Required**: Uses 4D's `METHOD GET CODE` and `METHOD SET CODE` for instrumentation
- **Multiple Report Formats**: Text, JSON, HTML, and lcov formats
- **Automatic Discovery**: Automatically finds and instruments host project methods
- **Test Isolation**: Restores original code after tests complete
- **CI/CD Ready**: Generates lcov format compatible with major CI platforms

### What Gets Measured

Coverage tracks **line execution** for:
- Project methods in the host application
- Class methods in the host application
- Functions called by your tests

Coverage **excludes**:
- Test methods themselves
- Testing framework methods
- Comments and blank lines
- Non-executable statements (e.g., `End if`, `Function declarations`)

## Quick Start

### Enable Coverage

```bash
# Basic coverage with text output
make test-coverage

# Generate HTML report
make test-coverage-html

# Generate lcov for CI/CD
make test-coverage-lcov
```

### View Results

Text output appears in the console:
```
=== Code Coverage Report ===

Overall Coverage: 87.50%
Lines Covered: 350 / 400
Methods Tracked: 25

=== Method Coverage ===

UserService.validateEmail
  [==================  ] 95.00% (19/20 lines)
  Uncovered lines: 15
```

## How It Works

The coverage system operates in five phases:

### 1. Discovery Phase
```
Scans host project → Identifies methods → Filters test/framework methods
```

The framework automatically discovers all project methods using `METHOD GET NAMES` and filters out:
- Methods with names matching `@Test@` or `Test@`
- Testing framework methods (`Testing_@`, `TestErrorHandler`, etc.)
- Private utility methods (starting with `_`)

### 2. Instrumentation Phase
```
Get original code → Inject counters → Update method → Store backup
```

For each method:
1. Retrieves source code using `METHOD GET CODE`
2. Parses code to identify executable lines
3. Injects execution counters at strategic points
4. Updates method using `METHOD SET CODE`
5. Stores original code for restoration

Example instrumentation:
```4d
// Original code
If ($user.active)
    $result:=True
End if

// Instrumented code
CoverageRecordLine("UserService"; 1)
If ($user.active)
    CoverageRecordLine("UserService"; 2)
    $result:=True
End if
```

The `CoverageRecordLine` project method handles Storage access with proper `Use...End use` blocks for thread safety.

### 3. Execution Phase
```
Run tests → Execute instrumented code → Increment counters
```

As tests run:
- Instrumented code increments line counters in shared `Storage.coverage.data`
- Each line's execution count is tracked independently
- Multiple executions of the same line accumulate

### 4. Collection Phase
```
Collect counter data → Calculate statistics → Identify uncovered lines
```

After tests complete:
- Copies coverage data from shared storage to local objects
- Calculates coverage percentages per method
- Identifies which lines were never executed
- Aggregates statistics across all tracked methods

### 5. Restoration Phase
```
Restore original code → Generate reports → Clean up storage
```

Finally:
- Restores all instrumented methods to their original code
- Generates requested report format(s)
- Cleans up shared storage
- Includes coverage data in test results

## Configuration

### Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `coverage` | `true`, `enabled` | (disabled) | Enable coverage tracking |
| `coverageFormat` | `text`, `json`, `html`, `lcov` | `text` | Report format |
| `coverageOutput` | File path | (console) | Save report to file |
| `coverageMethods` | Method patterns | (auto) | Specific methods to track |

### Examples

```bash
# Enable with defaults
tool4d --project MyProject.4DProject --startup-method "test" --user-param "coverage=true"

# Custom format and output
tool4d --project MyProject.4DProject --startup-method "test" --user-param "coverage=true coverageFormat=html coverageOutput=reports/coverage.html"

# Track specific methods only
tool4d --project MyProject.4DProject --startup-method "test" --user-param "coverage=true coverageMethods=UserService,OrderProcessor"

# Combined with test filtering
tool4d --project MyProject.4DProject --startup-method "test" --user-param "coverage=true tags=unit coverageFormat=html coverageOutput=coverage/unit.html"
```

### Method Patterns

When specifying `coverageMethods`, use comma-separated patterns:

```bash
# Exact method names
coverageMethods=UserService,OrderProcessor,PaymentHandler

# Wildcard patterns (not yet implemented)
coverageMethods=User*,*Service,Order*
```

## Report Formats

### Text Format

**Use Case**: Console output, quick checks, development

**Example**:
```
=== Code Coverage Report ===

Overall Coverage: 85.50%
Lines Covered: 342 / 400
Methods Tracked: 25
Duration: 1234ms

=== Method Coverage ===

PaymentProcessor.validateCard
  [=====               ] 25.00% (5/20 lines)
  Uncovered lines: 1-4, 6-8, 10-15, 17-20

UserService.validateEmail
  [==================  ] 95.00% (19/20 lines)
  Uncovered lines: 15

OrderProcessor.calculateTotal
  [====================] 100.00% (40/40 lines)
```

**Features**:
- ASCII progress bars
- Sorted by coverage (worst first)
- Uncovered line ranges
- Human-readable statistics

### JSON Format

**Use Case**: Programmatic consumption, custom reporting, CI/CD

**Example**:
```json
{
  "summary": {
    "totalLines": 400,
    "coveredLines": 342,
    "uncoveredLines": 58,
    "coveragePercent": 85.5,
    "methodCount": 25,
    "duration": 1234
  },
  "methods": [
    {
      "method": "UserService.validateEmail",
      "totalLines": 20,
      "coveredLines": 19,
      "uncoveredLines": 1,
      "coveragePercent": 95.0,
      "uncoveredLines": [15]
    }
  ],
  "format": "json",
  "version": "1.0"
}
```

**Features**:
- Structured data
- Complete statistics
- Line-level details
- Easy parsing

### HTML Format

**Use Case**: Visual reports, team sharing, documentation

**Example**: Interactive web page with:
- Color-coded coverage levels:
  - 🟢 Green (≥90%): Excellent coverage
  - 🟡 Yellow (≥75%): Good coverage
  - 🟠 Orange (≥50%): Moderate coverage
  - 🔴 Red (<50%): Poor coverage
- Progress bars for each method
- Sortable tables
- Responsive design

**Features**:
- Beautiful visual presentation
- No external dependencies
- Self-contained HTML file
- Mobile-friendly

### LCOV Format

**Use Case**: CI/CD integration, coverage tracking tools

**Example**:
```
TN:
SF:UserService
DA:1,2
DA:2,2
DA:3,0
DA:4,1
LF:4
LH:3
end_of_record
```

**Compatible With**:
- GitLab CI/CD coverage visualization
- GitHub Actions coverage reports
- SonarQube
- Codecov
- Coveralls
- Jenkins
- CircleCI

**Features**:
- Industry standard format
- Line-level execution counts
- Tool interoperability

## Best Practices

### 1. Set Coverage Goals

Establish coverage targets for different code types:

```bash
# Critical business logic: 90%+
make test-coverage-unit coverageMethods=UserService,OrderProcessor,PaymentHandler

# General application code: 80%+
make test-coverage

# Integration points: 70%+
make test-coverage-integration
```

### 2. Focus on Business Logic

Coverage is most valuable for:
- ✅ Business rules and validation
- ✅ Data transformation logic
- ✅ Complex calculations
- ✅ Error handling paths

Less valuable for:
- ❌ Getters/setters
- ❌ Simple property assignments
- ❌ Framework boilerplate
- ❌ Auto-generated code

### 3. Review Uncovered Lines

When coverage is low, investigate:

1. **Missing Tests**: Are there untested code paths?
2. **Dead Code**: Is the uncovered code actually needed?
3. **Error Handling**: Are error paths tested?
4. **Edge Cases**: Are boundary conditions covered?

### 4. Use with CI/CD

```yaml
# .gitlab-ci.yml
test:
  script:
    - make test-coverage-lcov
  coverage: '/Overall Coverage: (\d+\.?\d*)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/lcov.info
```

### 5. Track Coverage Over Time

```bash
# Save coverage reports with timestamps
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true coverageFormat=json coverageOutput=coverage/$(date +%Y%m%d).json"

# Compare coverage changes
diff coverage/20241101.json coverage/20241102.json
```

### 6. Combine with Test Filtering

```bash
# Unit test coverage (fast feedback)
make test-coverage-unit-html

# Integration test coverage (thorough validation)
make test-coverage-integration

# Feature-specific coverage
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true tags=payments coverageFormat=html coverageOutput=coverage/payments.html"
```

## Advanced Usage

### Custom Method Selection

Control which methods are instrumented:

```bash
# Track specific methods
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true coverageMethods=UserService,OrderService,PaymentService"

# Default behavior (all non-test methods)
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true"
```

### Multiple Report Formats

Generate multiple reports in one run:

```bash
# Run tests once, generate multiple reports programmatically
# (Note: Current implementation supports one format per run)
# Alternative: Run multiple times with different formats

make test-coverage-html
make test-coverage-lcov
make test-coverage-json
```

### Coverage Data Access

Access coverage data programmatically:

```4d
// From host project after running tests
var $runner : cs.TestRunner
$runner:=cs.TestRunner.new(cs; Storage; New object("coverage"; "true"))
$runner.run()

var $results : Object
$results:=$runner.getResults()

var $coverage : Object
$coverage:=$results.coverage

// Access statistics
var $percent : Real
$percent:=$coverage.coveragePercent

var $covered : Integer
$covered:=$coverage.coveredLines

var $total : Integer
$total:=$coverage.totalLines
```

### Parallel Execution

Coverage works with parallel test execution:

```bash
# Parallel tests with coverage
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true parallel=true maxWorkers=4"
```

Each worker process tracks its own coverage, then data is merged at the end.

## CI/CD Integration

### GitLab CI

```yaml
# .gitlab-ci.yml
test_with_coverage:
  stage: test
  script:
    # Run tests with coverage
    - make test-coverage-lcov
  coverage: '/Overall Coverage: (\d+\.?\d*)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/lcov.info
    paths:
      - coverage/
    when: always
    expire_in: 30 days
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
```

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test with Coverage
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install tool4d
        run: make tool4d
      
      - name: Run tests with coverage
        run: make test-coverage-lcov
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: 4d-coverage
```

### Jenkins

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    stages {
        stage('Test with Coverage') {
            steps {
                sh 'make test-coverage-lcov'
            }
        }
    }
    
    post {
        always {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'coverage',
                reportFiles: 'report.html',
                reportName: 'Coverage Report'
            ])
        }
    }
}
```

## Troubleshooting

### Coverage Shows 0% or No Data

**Possible Causes**:
1. No methods discovered for instrumentation
2. Instrumentation failed
3. Tests didn't execute instrumented code

**Solutions**:
```bash
# Check which methods are being tracked
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true" | grep "Coverage: Instrumented"

# Verify method names
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverageMethods=SpecificMethod"

# Check test execution
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true format=json"
```

### Instrumentation Fails

**Possible Causes**:
1. METHOD SET CODE permission issues
2. Malformed code
3. Syntax errors in original code

**Solutions**:
- Check 4D permissions for method modification
- Verify original code compiles successfully
- Review error messages in test output

### Coverage Report Not Generated

**Possible Causes**:
1. Invalid output path
2. Missing parent directory
3. Permission issues

**Solutions**:
```bash
# Ensure directory exists
mkdir -p coverage

# Use absolute path
tool4d --project MyProject.4DProject --startup-method "test" \
  --user-param "coverage=true coverageOutput=$(pwd)/coverage/report.html"

# Check permissions
ls -la coverage/
```

### Performance Impact

**Issue**: Tests run slower with coverage enabled

**Expected Behavior**: 
- ~20-40% slower due to instrumentation overhead
- More code = more overhead

**Optimization**:
```bash
# Track specific methods only
coverageMethods=CriticalService1,CriticalService2

# Use parallel execution
parallel=true coverage=true

# Run coverage selectively in CI
if: ${{ github.event_name == 'pull_request' }}
```

### Memory Issues

**Issue**: Out of memory errors with coverage

**Solutions**:
- Instrument fewer methods
- Use parallel execution with lower worker count
- Increase 4D memory allocation

## Example Workflows

### Development Workflow

```bash
# Quick coverage check during development
make test-coverage

# Full coverage with HTML report for review
make test-coverage-html
open coverage/report.html
```

### Pre-Commit Workflow

```bash
# Check unit test coverage before committing
make test-coverage-unit

# Ensure coverage meets threshold (manual check)
# TODO: Add automated threshold checking
```

### CI/CD Workflow

```bash
# Generate machine-readable coverage for CI
make test-coverage-lcov

# Archive HTML report as artifact
make test-coverage-html

# Parse coverage percentage for badges
grep "Overall Coverage:" coverage/report.txt | cut -d' ' -f3
```

### Release Workflow

```bash
# Full coverage report for release documentation
make test-coverage-html
cp coverage/report.html docs/coverage/v1.2.0.html

# Generate coverage trends
./scripts/generate-coverage-trends.sh
```

## Future Enhancements

Planned improvements for coverage support:

1. **Branch Coverage**: Track conditional branches (if/else paths)
2. **Function Coverage**: Track which functions were called
3. **Coverage Thresholds**: Automatic pass/fail based on coverage percentage
4. **Coverage Diff**: Show coverage changes between commits
5. **Wildcard Patterns**: Support `User*` patterns in `coverageMethods`
6. **Coverage Badges**: Generate SVG badges for README
7. **Incremental Coverage**: Track only changed files
8. **Coverage Annotations**: Source code annotations showing coverage

## References

- [4D METHOD GET CODE Documentation](https://developer.4d.com/docs/commands/method-get-code)
- [4D METHOD SET CODE Documentation](https://developer.4d.com/docs/commands/method-set-code)
- [LCOV Format Specification](http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php)
- [GitLab Code Coverage](https://docs.gitlab.com/ee/ci/testing/code_coverage.html)
- [Testing Guide](guide.md)
