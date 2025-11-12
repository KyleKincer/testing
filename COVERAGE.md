# Code Coverage Implementation Summary

## Overview

This document provides a technical summary of the code coverage implementation for the 4D Unit Testing Framework.

## Implementation Approach

The coverage system uses **runtime instrumentation** via 4D's `METHOD GET CODE` and `METHOD SET CODE` commands to inject execution tracking into host project methods.

## Architecture

### Core Components

1. **CoverageTracker** (`CoverageTracker.4dm`)
   - Manages coverage data storage in shared `Storage.coverage`
   - Records line execution counts
   - Calculates coverage statistics
   - Supports data merging for parallel execution

2. **CodeInstrumenter** (`CodeInstrumenter.4dm`)
   - Retrieves method source code using `METHOD GET CODE`
   - Injects execution counters at executable lines
   - Updates methods using `METHOD SET CODE`
   - Stores original code for restoration

3. **CoverageReporter** (`CoverageReporter.4dm`)
   - Generates reports in multiple formats (text, JSON, HTML, lcov)
   - Calculates coverage percentages
   - Identifies uncovered lines
   - Creates visual representations

4. **TestRunner Integration**
   - Coverage initialization from user parameters
   - Pre-test instrumentation
   - Post-test restoration and reporting
   - Automatic method discovery

## Instrumentation Strategy

### Code Analysis

The instrumenter identifies executable lines by:
- Skipping comments (`//`, `/* */`)
- Skipping blank lines
- Skipping structure keywords (`End if`, `End case`, etc.)
- Skipping declarations (`Function`, `property`, `Class constructor`)
- Including all other statements

### Counter Injection

For each executable line, the instrumenter injects a call to the shared project method `CoverageRecordLine`:
```4d
CoverageRecordLine("MethodName"; LineNumber)
```

This approach:
- Uses a project method wrapper for proper `Use...End use` handling
- Shared storage access is properly synchronized
- Thread-safe for parallel execution
- Preserves line numbers in original code
- Accumulates counts for multiply-executed lines
- Maintains proper indentation

The `CoverageRecordLine` method handles the Storage access:
```4d
Use (Storage.coverage.data)
    If (Storage.coverage.data[$methodName]=Null)
        Storage.coverage.data[$methodName]:=New shared object
    End if 
    
    Use (Storage.coverage.data[$methodName])
        var $currentCount : Integer
        $currentCount:=Num(Storage.coverage.data[$methodName][String($lineNumber)])
        Storage.coverage.data[$methodName][String($lineNumber)]:=$currentCount+1
    End use 
End use 
```

### Example

**Original Code:**
```4d
Function validateUser($email : Text) : Boolean
    If ($email="")
        return False
    End if
    return True
```

**Instrumented Code:**
```4d
Function validateUser($email : Text) : Boolean
    CoverageRecordLine("UserService"; 2)
    If ($email="")
        CoverageRecordLine("UserService"; 3)
        return False
    End if
    CoverageRecordLine("UserService"; 5)
    return True
```

## Data Flow

```
1. User enables coverage via parameters
   ↓
2. TestRunner discovers methods to track
   ↓
3. CodeInstrumenter:
   - Gets original code via METHOD GET CODE
   - Parses and injects counters
   - Updates code via METHOD SET CODE
   - Stores backup of original code
   ↓
4. CoverageTracker initializes shared storage
   ↓
5. Tests execute (instrumented code increments counters)
   ↓
6. CoverageTracker collects data from shared storage
   ↓
7. CodeInstrumenter restores original code
   ↓
8. CoverageReporter generates requested format
   ↓
9. Results included in test output
```

## Key Design Decisions

### 1. Shared Storage with Project Method Wrapper

**Decision**: Use `Storage.coverage.data` for counter storage, accessed via `CoverageRecordLine` project method

**Rationale**:
- Thread-safe for parallel execution (proper `Use...End use` handling)
- Accessible from instrumented code (shared project method)
- Avoids injecting complex `Use...End use` blocks in instrumented code
- Clean, simple instrumentation (single method call)
- Persists across method calls
- Easy cleanup after tests

### 2. Line-Level Granularity

**Decision**: Track individual line execution, not branch coverage

**Rationale**:
- Simpler instrumentation logic
- Easier to implement correctly
- Sufficient for most use cases
- Foundation for future branch coverage

### 3. Automatic Method Discovery

**Decision**: Auto-discover all non-test methods by default

**Rationale**:
- Zero configuration for most users
- Comprehensive coverage by default
- Can be overridden when needed
- Excludes framework and test methods

### 4. Code Restoration

**Decision**: Always restore original code, even on errors

**Rationale**:
- Prevents leaving corrupted code
- Ensures clean state for next run
- Critical for production safety
- Required for repeated test runs

### 5. Multiple Report Formats

**Decision**: Support text, JSON, HTML, and lcov formats

**Rationale**:
- Text: Human-readable console output
- JSON: Programmatic consumption
- HTML: Visual reporting and sharing
- LCOV: Industry standard for CI/CD

## Performance Considerations

### Instrumentation Overhead

- Method discovery: O(n) where n = number of methods
- Code parsing: O(m) where m = lines per method
- Counter injection: Adds 1 line per executable line
- Storage access: Minimal overhead (shared object lookup)

### Runtime Impact

Expected slowdown with coverage enabled:
- Small projects (<100 methods): 10-20%
- Medium projects (100-500 methods): 20-30%
- Large projects (>500 methods): 30-40%

### Optimization Strategies

1. **Selective Instrumentation**: Use `coverageMethods` parameter
2. **Parallel Execution**: Distribute overhead across workers
3. **Efficient Storage Access**: Direct property access, no iteration
4. **Lazy Evaluation**: Only calculate stats when needed

## Testing

### Coverage Test Suite

`CoverageTest.4dm` validates:
- CoverageTracker initialization and data collection
- Line execution recording
- Statistics calculation
- Uncovered line identification
- CodeInstrumenter line detection
- Indentation extraction
- CoverageReporter format generation
- Data merging for parallel execution

### Test Coverage

The coverage implementation itself has:
- 15 test methods
- Coverage of core functionality
- Edge case handling
- Format validation

## Future Enhancements

### Planned Features

1. **Branch Coverage**: Track if/else, case branches
2. **Function Coverage**: Track function call coverage
3. **Coverage Thresholds**: Fail tests below threshold
4. **Coverage Diff**: Show changes between runs
5. **Wildcard Patterns**: Support `User*` in `coverageMethods`
6. **Incremental Coverage**: Only track changed files
7. **Source Annotations**: Show coverage in source files

### Technical Challenges

1. **Branch Coverage**: Requires more sophisticated code analysis
2. **Performance**: Branch coverage adds more instrumentation points
3. **Accuracy**: Handling complex control flow (nested loops, etc.)
4. **Thread Safety**: Ensuring data consistency in parallel execution

## Integration Points

### TestRunner Integration

Coverage integrates at these TestRunner lifecycle points:
- `Class constructor`: Parse coverage parameters
- `run()`: Setup/teardown coverage
- `_initializeCoverage()`: Initialize components
- `_setupCoverage()`: Instrument methods
- `_teardownCoverage()`: Restore and report
- `results`: Include coverage in test results

### Storage Integration

Coverage uses host Storage object:
- Passed from host via `Testing_RunTestsWithCs`
- Used for method access permissions
- Stores coverage data during execution
- Cleaned up after collection

### CI/CD Integration

Coverage outputs integrate with:
- GitLab: Coverage percentage parsing, lcov reports
- GitHub: Codecov, Coveralls integration
- Jenkins: HTML report publishing
- SonarQube: lcov import

## Limitations

### Current Limitations

1. **No Branch Coverage**: Only line execution tracked
2. **No Compiled Mode**: Works in interpreted mode only
3. **Single Format Per Run**: Can't generate multiple formats simultaneously
4. **No Source Maps**: Line numbers may shift with instrumentation
5. **Method-Level Only**: Can't track individual function coverage within classes

### Known Issues

1. Complex string literals may confuse line detection
2. Multiline statements treated as single line
3. Performance impact on large codebases
4. Memory usage scales with number of methods

## Best Practices

### For Framework Users

1. Enable coverage in CI/CD pipelines
2. Set coverage thresholds for quality gates
3. Review uncovered lines in critical code
4. Use HTML reports for team communication
5. Track coverage trends over time

### For Framework Developers

1. Add tests for new instrumentation logic
2. Validate all report formats
3. Test with large codebases
4. Profile performance impact
5. Document edge cases

## References

- [Coverage Guide](docs/coverage-guide.md) - User-facing documentation
- [4D METHOD GET CODE](https://developer.4d.com/docs/commands/method-get-code)
- [4D METHOD SET CODE](https://developer.4d.com/docs/commands/method-set-code)
- [LCOV Format](http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php)

## Change Log

### v1.0 (2024-11-05)

- Initial implementation of code coverage
- CoverageTracker, CodeInstrumenter, CoverageReporter classes
- TestRunner integration
- Text, JSON, HTML, lcov report formats
- Automatic method discovery
- Coverage test suite
- Documentation and examples
- Makefile targets for coverage commands
