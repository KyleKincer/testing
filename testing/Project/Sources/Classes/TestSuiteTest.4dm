// Comprehensive tests for TestSuite functionality
Class constructor()

Function test_test_suite_initialization($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Create a TestSuite for ExampleTest class
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; []; Null:C1517)
	
	$assert.isNotNull($t; $suite; "TestSuite should initialize")
	$assert.areEqual($t; "ExampleTest"; $suite.class.name; "Should store the class reference")
	$assert.areEqual($t; "human"; $suite.outputFormat; "Should store output format")
	$assert.isNotNull($t; $suite.testFunctions; "Should initialize testFunctions collection")
	$assert.isNotNull($t; $suite.classInstance; "Should create class instance")

Function test_test_method_discovery($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; []; Null:C1517)
	
	// Should discover test methods
	$assert.isTrue($t; $suite.testFunctions.length>0; "Should discover test methods")
	
	// Verify all discovered methods start with "test_"
	var $testFunction : cs:C1710.TestFunction
	For each ($testFunction; $suite.testFunctions)
		$assert.isTrue($t; $testFunction.functionName="test_@"; "All test methods should start with 'test_', found: "+$testFunction.functionName)
	End for each 

Function test_pattern_filtering_no_patterns($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	// Create TestSuite with no patterns (empty collection)
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; []; Null:C1517)
	
	// Should include all test methods when no patterns specified
	$assert.isTrue($t; $suite.testFunctions.length>0; "Should include all tests when no patterns specified")

Function test_pattern_filtering_with_suite_match($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	// Create TestSuite with pattern matching the suite name
	var $patterns : Collection
	$patterns:=["ExampleTest"]
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; $patterns; Null:C1517)
	
	// Should include all test methods when suite name matches
	$assert.isTrue($t; $suite.testFunctions.length>0; "Should include all tests when suite name matches pattern")

Function test_pattern_filtering_with_method_match($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	// Create TestSuite with pattern matching specific method
	var $patterns : Collection
	$patterns:=["test_areEqual_pass"]
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; $patterns; Null:C1517)
	
	// Should only include the matching test method
	$assert.areEqual($t; 1; $suite.testFunctions.length; "Should include only matching test method")
	$assert.areEqual($t; "test_areEqual_pass"; $suite.testFunctions[0].functionName; "Should include the correct test method")

Function test_pattern_filtering_with_wildcard($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	// Create TestSuite with wildcard pattern
	var $patterns : Collection
	$patterns:=["*True*"]
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; $patterns; Null:C1517)
	
	// Should include test methods matching the pattern
	$assert.isTrue($t; $suite.testFunctions.length>0; "Should include tests matching wildcard")
	
	// Verify all included methods contain "True"
	var $testFunction : cs:C1710.TestFunction
	For each ($testFunction; $suite.testFunctions)
		$assert.isTrue($t; $testFunction.functionName="@True@"; "Included methods should match wildcard pattern, found: "+$testFunction.functionName)
	End for each 

Function test_pattern_filtering_no_matches($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	// Create TestSuite with pattern that won't match anything
	var $patterns : Collection
	$patterns:=["nonexistent_test"]
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; $patterns; Null:C1517)
	
	// Should include no test methods when pattern doesn't match
	$assert.areEqual($t; 0; $suite.testFunctions.length; "Should include no tests when pattern doesn't match")

Function test_has_method_detection($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Use SetupTeardownTest which has setup/teardown methods
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710.SetupTeardownTest
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($testClass; "human"; []; Null:C1517)
	
	// Test _hasMethod functionality
	$assert.isTrue($t; $suite._hasMethod("setup"); "Should detect setup method")
	$assert.isTrue($t; $suite._hasMethod("teardown"); "Should detect teardown method")
	$assert.isTrue($t; $suite._hasMethod("beforeEach"); "Should detect beforeEach method")
	$assert.isTrue($t; $suite._hasMethod("afterEach"); "Should detect afterEach method")
	$assert.isFalse($t; $suite._hasMethod("nonexistent"); "Should not detect non-existent method")

Function test_pattern_matching_functionality($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($exampleClass; "human"; []; Null:C1517)
	
	// Test the _matchesPattern method
	$assert.isTrue($t; $suite._matchesPattern("test_example"; "test_example"); "Should match exact text")
	$assert.isTrue($t; $suite._matchesPattern("test_example"; "*example"); "Should match with wildcard")
	$assert.isTrue($t; $suite._matchesPattern("test_example"; "test_*"); "Should match with wildcard")
	$assert.isTrue($t; $suite._matchesPattern("anything"; "*"); "Should match universal pattern")
	$assert.isFalse($t; $suite._matchesPattern("test_example"; "different"); "Should not match different text")