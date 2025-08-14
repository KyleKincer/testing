// Tests for parameter parsing functionality
Class constructor()

Function test_parse_single_parameter($t : cs:C1710.Testing)
	
	// We can't directly test _parseUserParams because it reads from system parameters
	// Instead, we'll test the overall behavior through the public interface
	
	// Create a TestRunner to test parameter-dependent behavior
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that output format is set (depends on current user parameters)
	$t.assert.isTrue($t; ($runner.outputFormat="human") || ($runner.outputFormat="json"); "Output format should be either human or json")
	$t.assert.areEqual($t; 0; $runner.testPatterns.length; "Should have no test patterns by default")

Function test_pattern_parsing_logic($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test pattern matching behavior
	$t.assert.isTrue($t; $runner._matchesPattern("test"; "test"); "Should match exact string")
	$t.assert.isTrue($t; $runner._matchesPattern("test123"; "test*"); "Should match with wildcard")
	$t.assert.isTrue($t; $runner._matchesPattern("123test"; "*test"); "Should match with leading wildcard")
	$t.assert.isTrue($t; $runner._matchesPattern("123test456"; "*test*"); "Should match with surrounding wildcards")
	$t.assert.isFalse($t; $runner._matchesPattern("different"; "test"); "Should not match different string")

Function test_empty_pattern_handling($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test empty pattern behavior
	$t.assert.isFalse($t; $runner._matchesPattern("test"; ""); "Empty pattern should not match")
	$t.assert.isFalse($t; $runner._matchesPattern(""; "test"); "Empty text should not match non-empty pattern")

Function test_case_sensitivity($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// 4D's @ operator is case-insensitive by default
	$t.assert.isTrue($t; $runner._matchesPattern("Test"; "test"); "4D pattern matching is case insensitive")
	$t.assert.isTrue($t; $runner._matchesPattern("test"; "Test"); "4D pattern matching is case insensitive")
	$t.assert.isTrue($t; $runner._matchesPattern("Test"; "Test"); "Same case should match")

Function test_special_characters_in_patterns($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test patterns with special characters
	$t.assert.isTrue($t; $runner._matchesPattern("test_method"; "test_method"); "Should handle underscores")
	$t.assert.isTrue($t; $runner._matchesPattern("test-method"; "test-method"); "Should handle hyphens")
	$t.assert.isTrue($t; $runner._matchesPattern("TestClass.method"; "TestClass.method"); "Should handle dots")
	$t.assert.isTrue($t; $runner._matchesPattern("test_method"; "*_method"); "Should match with underscore wildcard")

Function test_multiple_wildcard_patterns($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test complex wildcard patterns
	$t.assert.isTrue($t; $runner._matchesPattern("test_method_example"; "*method*"); "Should match middle wildcard")
	$t.assert.isTrue($t; $runner._matchesPattern("ExampleTest"; "*Test"); "Should match suffix wildcard")
	$t.assert.isTrue($t; $runner._matchesPattern("TestExample"; "Test*"); "Should match prefix wildcard")

Function test_edge_case_patterns($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test edge cases
	$t.assert.isTrue($t; $runner._matchesPattern("anything"; "*"); "Universal wildcard should match anything")
	$t.assert.isTrue($t; $runner._matchesPattern(""; "*"); "Universal wildcard should match empty string")
	// Note: 4D doesn't have escape sequences for @ patterns, so literal asterisk matching is not supported

Function test_parameter_validation($t : cs:C1710.Testing)
	
	// Test that TestRunner handles invalid parameters gracefully
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Should not crash with default initialization
	$t.assert.isNotNull($t; $runner.outputFormat; "Output format should be initialized")
	$t.assert.isNotNull($t; $runner.testPatterns; "Test patterns should be initialized")
	
	// Should handle empty test patterns gracefully
	var $exampleSuite : cs:C1710.TestSuite
	$exampleSuite:=cs:C1710.TestSuite.new(cs:C1710.ExampleTest; "human"; []; Null:C1517)
	
	$t.assert.isTrue($t; $runner._shouldIncludeTestSuite($exampleSuite); "Should include suite when no patterns specified")

Function test_suite_filtering_logic($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Manually set test patterns to test filtering logic
	$runner.testPatterns:=["ExampleTest"]
	
	var $exampleSuite : cs:C1710.TestSuite
	$exampleSuite:=cs:C1710.TestSuite.new(cs:C1710.ExampleTest; "human"; ["ExampleTest"]; Null:C1517)
	
	var $errorSuite : cs:C1710.TestSuite
	$errorSuite:=cs:C1710.TestSuite.new(cs:C1710.ErrorHandlingTest; "human"; ["ExampleTest"]; Null:C1517)
	
	$t.assert.isTrue($t; $runner._shouldIncludeTestSuite($exampleSuite); "Should include matching suite")
	$t.assert.isFalse($t; $runner._shouldIncludeTestSuite($errorSuite); "Should exclude non-matching suite")

Function test_wildcard_suite_filtering($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test wildcard filtering
	$runner.testPatterns:=["*Error*"]
	
	var $errorSuite : cs:C1710.TestSuite
	$errorSuite:=cs:C1710.TestSuite.new(cs:C1710.ErrorHandlingTest; "human"; ["*Error*"]; Null:C1517)
	
	var $exampleSuite : cs:C1710.TestSuite
	$exampleSuite:=cs:C1710.TestSuite.new(cs:C1710.ExampleTest; "human"; ["*Error*"]; Null:C1517)
	
	$t.assert.isTrue($t; $runner._shouldIncludeTestSuite($errorSuite); "Should include suite matching wildcard")
	$t.assert.isFalse($t; $runner._shouldIncludeTestSuite($exampleSuite); "Should exclude suite not matching wildcard")