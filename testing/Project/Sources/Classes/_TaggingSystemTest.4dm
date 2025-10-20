// Tests for the test tagging system
Class constructor()

Function test_tag_filtering_include($t : cs:C1710.Testing)
	
	// Test that tag filtering works for include tags
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new(Null:C1517; Null:C1517)
	
	// Manually set include tags to test filtering logic
	$runner.includeTags:=["fast"]
	$runner.excludeTags:=[]
	$runner.requireAllTags:=[]
	
	// Create a test function with tags from source code
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710._TaggingExampleTest
	var $classInstance : cs:C1710._TaggingExampleTest
	$classInstance:=cs:C1710._TaggingExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_basic_addition
	
	// Get actual class code for proper tag parsing
	var $testSuite : cs:C1710._TestSuite  
	$testSuite:=cs:C1710._TestSuite.new($testClass; "human"; []; Null:C1517)
	var $classCode : Text
	$classCode:=$testSuite._getClassCode()
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($testClass; $classInstance; $testMethod; "test_basic_addition"; $classCode)
	
	// The test should be included because test_basic_addition has "fast" tag in comment
	var $shouldInclude : Boolean
	$shouldInclude:=$runner._shouldIncludeTestByTags($testFunction)
	$t.assert.isTrue($t; $shouldInclude; "Should include test with matching tag")

Function test_tag_filtering_exclude($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new(Null:C1517; Null:C1517)
	
	// Set exclude tags
	$runner.includeTags:=[]
	$runner.excludeTags:=["slow"]
	$runner.requireAllTags:=[]
	
	// Create a test function with tags from source code
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710._TaggingExampleTest
	var $classInstance : cs:C1710._TaggingExampleTest
	$classInstance:=cs:C1710._TaggingExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_database_connection
	
	// Get actual class code for proper tag parsing
	var $testSuite : cs:C1710._TestSuite  
	$testSuite:=cs:C1710._TestSuite.new($testClass; "human"; []; Null:C1517)
	var $classCode : Text
	$classCode:=$testSuite._getClassCode()
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($testClass; $classInstance; $testMethod; "test_database_connection"; $classCode)
	
	// The test should be excluded because test_database_connection has "slow" tag in comment
	var $shouldInclude : Boolean
	$shouldInclude:=$runner._shouldIncludeTestByTags($testFunction)
	$t.assert.isFalse($t; $shouldInclude; "Should exclude test with excluded tag")

Function test_tag_parsing_from_comments($t : cs:C1710.Testing)
	
	// Test that tags are correctly parsed from comments
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710._TaggingExampleTest
	var $classInstance : cs:C1710._TaggingExampleTest
	$classInstance:=cs:C1710._TaggingExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_basic_addition
	
	// Get actual class code for proper tag parsing
	var $testSuite : cs:C1710._TestSuite  
	$testSuite:=cs:C1710._TestSuite.new($testClass; "human"; []; Null:C1517)
	var $classCode : Text
	$classCode:=$testSuite._getClassCode()
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($testClass; $classInstance; $testMethod; "test_basic_addition"; $classCode)
	
	// Should have "unit" and "fast" tags from comment
	$t.assert.isTrue($t; $testFunction.hasTags(["unit"]); "Should detect unit tag from comment")
	$t.assert.isTrue($t; $testFunction.hasTags(["fast"]); "Should detect fast tag from comment")
	$t.assert.isTrue($t; $testFunction.tags.length>=2; "Should have at least two tags")

Function test_default_unit_tag($t : cs:C1710.Testing)
	
	// Test that functions without tag comments get default "unit" tag
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	// Get actual class code for proper tag parsing
	var $testSuite : cs:C1710._TestSuite  
	$testSuite:=cs:C1710._TestSuite.new($testClass; "human"; []; Null:C1517)
	var $classCode : Text
	$classCode:=$testSuite._getClassCode()
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($testClass; $classInstance; $testMethod; "test_areEqual_pass"; $classCode)
	
	$t.assert.isTrue($t; $testFunction.hasTags(["unit"]); "Should have default unit tag")
	$t.assert.areEqual($t; 1; $testFunction.tags.length; "Should have exactly one tag")

Function test_tag_parameter_parsing($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new(Null:C1517; Null:C1517)
	
	// Test tag list parsing
	var $tags : Collection
	$tags:=$runner._parseTagList("unit,integration,slow")
	$t.assert.areEqual($t; 3; $tags.length; "Should parse three tags")
	$t.assert.areEqual($t; "unit"; $tags[0]; "First tag should be unit")
	$t.assert.areEqual($t; "integration"; $tags[1]; "Second tag should be integration")
	$t.assert.areEqual($t; "slow"; $tags[2]; "Third tag should be slow")
	
	// Test with spaces
	$tags:=$runner._parseTagList("unit, integration , slow")
	$t.assert.areEqual($t; 3; $tags.length; "Should handle spaces around tags")
	$t.assert.areEqual($t; "unit"; $tags[0]; "Should trim spaces from tags")
	
	// Test empty string
	$tags:=$runner._parseTagList("")
	$t.assert.areEqual($t; 0; $tags.length; "Empty string should return empty collection")

Function test_tag_filtering_no_filters($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new(Null:C1517; Null:C1517)
	
	// No filters set - should include all tests
	$runner.includeTags:=[]
	$runner.excludeTags:=[]
	$runner.requireAllTags:=[]
	
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($testClass; $classInstance; $testMethod; "test_areEqual_pass"; "")
	
	var $shouldInclude : Boolean
	$shouldInclude:=$runner._shouldIncludeTestByTags($testFunction)
	$t.assert.isTrue($t; $shouldInclude; "Should include all tests when no filters are set")

Function test_multiple_tags_in_comment($t : cs:C1710.Testing)
	
	// Test a function with multiple tags in comment
	var $testClass : 4D:C1709.Class
	$testClass:=cs:C1710._TaggingExampleTest
	var $classInstance : cs:C1710._TaggingExampleTest
	$classInstance:=cs:C1710._TaggingExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_large_collection_processing  // Has "integration, performance" tags
	
	// Get actual class code for proper tag parsing
	var $testSuite : cs:C1710._TestSuite  
	$testSuite:=cs:C1710._TestSuite.new($testClass; "human"; []; Null:C1517)
	var $classCode : Text
	$classCode:=$testSuite._getClassCode()
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($testClass; $classInstance; $testMethod; "test_large_collection_processing"; $classCode)
	
	// Should have both integration and performance tags
	$t.assert.isTrue($t; $testFunction.hasTags(["integration"]); "Should detect integration tag")
	$t.assert.isTrue($t; $testFunction.hasTags(["performance"]); "Should detect performance tag")
	$t.assert.isTrue($t; $testFunction.tags.length>=2; "Should have multiple tags")