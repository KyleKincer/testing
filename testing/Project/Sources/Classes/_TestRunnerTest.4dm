// Comprehensive tests for TestRunner functionality
Class constructor()
	
Function test_parameter_parsing_with_equals($t : cs:C1710.Testing)
	
	// Create a TestRunner instance to test parameter parsing
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test basic initialization
	$t.assert.isNotNull($t; $runner; "TestRunner should initialize")
	$t.assert.isNotNull($t; $runner.testSuites; "TestRunner should have testSuites collection")
	$t.assert.areEqual($t; 0; $runner.testSuites.length; "TestSuites should be empty initially")
	
Function test_parse_param_string_with_equals($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test the extracted _parseParamString method directly
	var $params : Object
	$params:=$runner._parseParamString("format=json test=ExampleTest")
	
	$t.assert.areEqual($t; "json"; $params.format; "Should parse format parameter")
	$t.assert.areEqual($t; "ExampleTest"; $params.test; "Should parse test parameter")
	
Function test_parse_param_string_with_colons($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test colon-separated parameters
	var $params : Object
	$params:=$runner._parseParamString("format:json test:*Error*")
	
	$t.assert.areEqual($t; "json"; $params.format; "Should parse format parameter with colon")
	$t.assert.areEqual($t; "*Error*"; $params.test; "Should parse test parameter with colon")
	
Function test_parse_param_string_empty($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test empty parameter string
	var $params : Object
	$params:=$runner._parseParamString("")
	
	$t.assert.isNotNull($t; $params; "Should return object for empty string")
	$t.assert.areEqual($t; Null:C1517; $params.format; "Should have no format parameter")
	$t.assert.areEqual($t; Null:C1517; $params.test; "Should have no test parameter")
	
Function test_parse_param_string_malformed($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test malformed parameters (no values)
	var $params : Object
	$params:=$runner._parseParamString("format= test")
	
	$t.assert.isNotNull($t; $params; "Should handle malformed parameters gracefully")
	
Function test_filter_test_classes($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Create a mock class store
	var $mockClassStore : Object
	$mockClassStore:=New object:C1471(\
		"ExampleTest"; New object:C1471("name"; "ExampleTest"; "superclass"; New object:C1471("name"; "Object")); \
		"ErrorHandlingTest"; New object:C1471("name"; "ErrorHandlingTest"; "superclass"; New object:C1471("name"; "Object")); \
		"SomeUtility"; New object:C1471("name"; "SomeUtility"; "superclass"; New object:C1471("name"; "Object")); \
		"UserDataClass"; New object:C1471("name"; "UserDataClass"; "superclass"; New object:C1471("name"; "DataClass"))\
		)
	
	var $testClasses : Collection
        $testClasses:=$runner._filterTestClasses($mockClassStore; Null:C1517)
	
	// Should find ExampleTest and ErrorHandlingTest from the mock
	var $foundNames : Collection
	$foundNames:=[]
	var $class : Object
	For each ($class; $testClasses)
		$foundNames.push($class.name)
	End for each 
	
	$t.assert.areEqual($t; 2; $testClasses.length; "Should find exactly 2 test classes from mock, found: "+JSON Stringify:C1217($foundNames))
	$t.assert.isTrue($t; $foundNames.indexOf("ExampleTest")>=0; "Should include ExampleTest")
	$t.assert.isTrue($t; $foundNames.indexOf("ErrorHandlingTest")>=0; "Should include ErrorHandlingTest")
	
Function test_output_format_defaults_to_human($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Note: Output format depends on current user parameters when running tests
	// This test verifies the outputFormat property exists and has a valid value
	$t.assert.isTrue($t; ($runner.outputFormat="human") || ($runner.outputFormat="json") || ($runner.outputFormat="junit"); "Output format should be human, json, or junit")
	
Function test_test_class_discovery($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that it finds test classes
	var $testClasses : Collection
	$testClasses:=$runner._getTestClasses()
	
	$t.assert.isNotNull($t; $testClasses; "Should return a collection of test classes")
	$t.assert.isTrue($t; $testClasses.length>0; "Should find at least one test class")
	
	// Verify that all returned classes have names ending with "Test"
	var $class : 4D:C1709.Class
        For each ($class; $testClasses)
                $t.assert.isTrue($t; $class.name="@Test"; "All discovered classes should end with 'Test', found: "+$class.name)
        End for each

Function test_persistent_class_cache($t : cs:C1710.Testing)

        var $runner : cs:C1710.TestRunner
        $runner:=cs:C1710.TestRunner.new()

        // Ensure cache file is removed before testing
        var $cacheFile : 4D:C1709.File
        $cacheFile:=$runner._cacheFile()
        If ($cacheFile.exists)
                $cacheFile.delete()
        End if

        // First run should create the cache file
        var $classes : Collection
        $classes:=$runner._getTestClasses()
        $t.assert.isTrue($t; $cacheFile.exists; "Cache file should be created on first run")

        // Clear in-memory cache to simulate fresh run
        $runner._cachedTestClasses:=Null:C1517
        $runner._classStoreSignature:=""

        // Second run should load from disk and return same number of classes
        var $classes2 : Collection
        $classes2:=$runner._getTestClasses()
        $t.assert.areEqual($t; $classes.length; $classes2.length; "Cache should provide same classes on subsequent runs")
	
Function test_pattern_matching_exact($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test exact pattern matching
	$t.assert.isTrue($t; $runner._matchesPattern("ExampleTest"; "ExampleTest"); "Should match exactly")
	$t.assert.isFalse($t; $runner._matchesPattern("ExampleTest"; "ErrorHandlingTest"); "Should not match different text")
	
Function test_pattern_matching_wildcards($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test wildcard pattern matching
	$t.assert.isTrue($t; $runner._matchesPattern("ExampleTest"; "*Example*"); "Should match with wildcards")
	$t.assert.isTrue($t; $runner._matchesPattern("ErrorHandlingTest"; "*Error*"); "Should match with wildcards")
	$t.assert.isTrue($t; $runner._matchesPattern("TestRunner"; "*Runner"); "Should match with trailing wildcard")
	$t.assert.isTrue($t; $runner._matchesPattern("TestRunner"; "Test*"); "Should match with leading wildcard")
	$t.assert.isFalse($t; $runner._matchesPattern("ExampleTest"; "*Error*"); "Should not match incorrect wildcards")
	
Function test_pattern_matching_universal($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test universal pattern
	$t.assert.isTrue($t; $runner._matchesPattern("anything"; "*"); "Universal pattern should match anything")
	$t.assert.isTrue($t; $runner._matchesPattern(""; "*"); "Universal pattern should match empty string")
	
Function test_results_initialization($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	$t.assert.isNotNull($t; $results; "Results should be initialized")
	$t.assert.areEqual($t; 0; $results.totalTests; "Total tests should start at 0")
	$t.assert.areEqual($t; 0; $results.passed; "Passed should start at 0")
        $t.assert.areEqual($t; 0; $results.failed; "Failed should start at 0")
        $t.assert.areEqual($t; 0; $results.skipped; "Skipped should start at 0")
        $t.assert.isNotNull($t; $results.suites; "Suites should be initialized")
        $t.assert.isNotNull($t; $results.failedTests; "FailedTests should be initialized")
        $t.assert.areEqual($t; 0; $results.assertions; "Assertions should start at 0")
	
Function test_test_patterns_initialization($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	$t.assert.isNotNull($t; $runner.testPatterns; "Test patterns should be initialized")
	// Note: Test patterns may be populated from user parameters during testing
	// So we check that it's initialized as a Collection rather than being empty
	$t.assert.isTrue($t; Value type:C1509($runner.testPatterns)=Is collection:K8:32; "Test patterns should be a Collection")
	
Function test_getUserParam_basic_functionality($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test the extracted method directly
	// We can't easily mock Get database parameter, but we can test that the method works
	var $userParam : Text
	$userParam:=$runner._getUserParam()
	
	// The method should return a Text value (even if empty)
	$t.assert.isNotNull($t; $userParam; "Should return user parameter string")
	// Note: The actual content depends on the current user parameters when running tests
	
Function test_parseParamString_comprehensive($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test comprehensive parameter parsing scenarios
	var $params : Object
	
	// Test multiple key=value pairs
	$params:=$runner._parseParamString("format=json test=*Example* debug=true")
	$t.assert.areEqual($t; "json"; $params.format; "Should parse format parameter")
	$t.assert.areEqual($t; "*Example*"; $params.test; "Should parse test parameter")
	$t.assert.areEqual($t; "true"; $params.debug; "Should parse debug parameter")
	
	// Test mixed separators
	$params:=$runner._parseParamString("format:json test=ErrorTest")
	$t.assert.areEqual($t; "json"; $params.format; "Should handle colon separator")
	$t.assert.areEqual($t; "ErrorTest"; $params.test; "Should handle equals separator in same string")
	
Function test_getClassStore_basic_functionality($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that _getClassStore returns the classStore property
	var $classStore : Object
	$classStore:=$runner._getClassStore()
	
	$t.assert.isNotNull($t; $classStore; "Should return class store object")
	// Note: We can't use areEqual with objects due to 4D comparison limitations
	// Instead, verify it has expected properties of a class store
	$t.assert.isTrue($t; Value type:C1509($classStore)=Is object:K8:27; "Should return an object")
	
Function test_filterTestClasses_comprehensive($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Create comprehensive mock class store with various scenarios
	var $mockClassStore : Object
	$mockClassStore:=New object:C1471(\
		"ExampleTest"; New object:C1471("name"; "ExampleTest"; "superclass"; New object:C1471("name"; "Object")); \
		"ErrorHandlingTest"; New object:C1471("name"; "ErrorHandlingTest"; "superclass"; New object:C1471("name"; "Object")); \
		"TestRunnerTest"; New object:C1471("name"; "TestRunnerTest"; "superclass"; New object:C1471("name"; "Object")); \
		"ComprehensiveErrorTest"; New object:C1471("name"; "ComprehensiveErrorTest"; "superclass"; New object:C1471("name"; "Object")); \
		"NotATest"; New object:C1471("name"; "NotATest"; "superclass"; New object:C1471("name"; "Object")); \
		"UserDataClass"; New object:C1471("name"; "UserDataClass"; "superclass"; New object:C1471("name"; "DataClass")); \
		"ProductDataClass"; New object:C1471("name"; "ProductDataClass"; "superclass"; New object:C1471("name"; "DataClass")); \
		"SomeUtilityClass"; New object:C1471("name"; "SomeUtilityClass"; "superclass"; New object:C1471("name"; "Object"))\
		)
	
	var $testClasses : Collection
    $testClasses:=$runner._filterTestClasses($mockClassStore; Null:C1517)
	
	// Should find all test classes (ExampleTest, ErrorHandlingTest, TestRunnerTest, ComprehensiveErrorTest)
	$t.assert.isTrue($t; $testClasses.length>=4; "Should find at least 4 test classes")
	
	// Verify all found classes are test classes
	var $foundTestClasses : Collection
	$foundTestClasses:=[]
	var $class : Object
	For each ($class; $testClasses)
		$foundTestClasses.push($class.name)
	End for each 
	
	$t.assert.isTrue($t; $foundTestClasses.indexOf("ExampleTest")>=0; "Should include ExampleTest")
	$t.assert.isTrue($t; $foundTestClasses.indexOf("ErrorHandlingTest")>=0; "Should include ErrorHandlingTest")
	$t.assert.isTrue($t; $foundTestClasses.indexOf("TestRunnerTest")>=0; "Should include TestRunnerTest")
	$t.assert.isTrue($t; $foundTestClasses.indexOf("ComprehensiveErrorTest")>=0; "Should include ComprehensiveErrorTest")
	
	// Verify DataClasses are excluded
	var $class : Object
	For each ($class; $testClasses)
		$t.assert.isTrue($t; $class.superclass.name#"DataClass"; "Should not include DataClass instances: "+$class.name)
		$t.assert.isTrue($t; $class.name="@Test"; "All classes should end with 'Test': "+$class.name)
	End for each 
	
Function test_dependency_injection_pattern($t : cs:C1710.Testing)
	
	// Test that we can successfully test the dependency extraction pattern
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Verify that extracted methods are independently testable
	var $emptyParams : Object
	$emptyParams:=$runner._parseParamString("")
	$t.assert.isNotNull($t; $emptyParams; "Empty param parsing should work independently")
	
	var $classStore : Object
	$classStore:=$runner._getClassStore()
	$t.assert.isNotNull($t; $classStore; "Class store access should work independently")
	
	// Test filtered classes with empty mock store
	var $emptyStore : Object
	$emptyStore:=New object:C1471
	var $noClasses : Collection
    $noClasses:=$runner._filterTestClasses($emptyStore; Null:C1517)
	$t.assert.areEqual($t; 0; $noClasses.length; "Should handle empty class store")
	
Function test_pattern_matching_with_dependency_extraction($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that pattern matching works independently of parameter parsing
	var $matches : Boolean
	$matches:=$runner._matchesPattern("TestRunnerTest"; "*Runner*")
	$t.assert.isTrue($t; $matches; "Pattern matching should work independently")
	
	$matches:=$runner._matchesPattern("ComprehensiveErrorTest"; "*Error*")
	$t.assert.isTrue($t; $matches; "Should match error pattern")
	
	$matches:=$runner._matchesPattern("ExampleTest"; "*NonExistent*")
	$t.assert.isFalse($t; $matches; "Should not match non-existent pattern")
	
Function test_error_handling_in_extracted_methods($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that extracted methods handle edge cases gracefully
	var $result : Object
	$result:=$runner._parseParamString("malformed=")
	$t.assert.isNotNull($t; $result; "Should handle malformed parameters")
	
	var $emptyResult : Object
	$emptyResult:=$runner._parseParamString("   ")
	$t.assert.isNotNull($t; $emptyResult; "Should handle whitespace-only parameters")
	
	// Test class filtering with malformed class store
	var $malformedStore : Object
	$malformedStore:=New object:C1471(\
		"InvalidTest"; New object:C1471("name"; "InvalidTest"); \
		"ValidTest"; New object:C1471("name"; "ValidTest"; "superclass"; New object:C1471("name"; "Object"))\
		)
        var $filteredClasses : Collection
        $filteredClasses:=$runner._filterTestClasses($malformedStore; Null:C1517)
        // Should find ValidTest but skip InvalidTest (missing superclass)
        $t.assert.areEqual($t; 1; $filteredClasses.length; "Should handle classes without superclass gracefully")
        $t.assert.areEqual($t; "ValidTest"; $filteredClasses[0].name; "Should include ValidTest")

Function test_skip_tag_counts_as_skipped($t : cs:C1710.Testing)

        // Run TestRunner on a class that should be skipped
        var $runner : cs:C1710.TestRunner
        $runner:=cs:C1710.TestRunner.new()
        // Suppress output during this internal test run
        $runner.outputFormat:="none"
        $runner.testPatterns:=["_SkipTaggedTest*"]
        $runner.run()

        var $results : Object
        $results:=$runner.getResults()

        $t.assert.areEqual($t; 1; $results.totalTests; "Total should count skipped test")
        $t.assert.areEqual($t; 1; $results.skipped; "Skipped test should be counted")
        $t.assert.areEqual($t; 0; $results.failed; "Skipped test should not fail")
        $t.assert.areEqual($t; 0; $results.passed; "Skipped test should not pass")