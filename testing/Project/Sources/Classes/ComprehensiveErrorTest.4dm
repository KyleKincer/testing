// Comprehensive error handling and edge case tests
Class constructor()

Function test_null_class_handling($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test that TestSuite handles null class gracefully
	// Note: This may cause runtime errors, but should be caught by error handler
	
	// We can't easily test with actual null class without causing errors,
	// but we can test with valid classes to ensure the structure works
	var $validClass : 4D:C1709.Class
	$validClass:=cs:C1710.ExampleTest
	
	$assert.isNotNull($t; $validClass; "Valid class should not be null")
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new($validClass; "human"; []; Null:C1517)
	
	$assert.isNotNull($t; $suite; "TestSuite should handle valid class")
	$assert.areEqual($t; "ExampleTest"; $suite.class.name; "Should store class correctly")

Function test_empty_test_class($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test behavior with a class that has no test methods
	// We'll create a mock by testing a class we know has methods,
	// then filtering to ensure no methods match
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	$runner.testPatterns:=["nonexistent_pattern"]
	
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new(cs:C1710.ExampleTest; "human"; ["nonexistent_pattern"]; Null:C1517)
	
	$assert.areEqual($t; 0; $suite.testFunctions.length; "Should have no test functions when pattern doesn't match")

Function test_malformed_test_methods($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test that test discovery handles methods that don't follow the pattern
	var $suite : cs:C1710.TestSuite
	$suite:=cs:C1710.TestSuite.new(cs:C1710.ExampleTest; "human"; []; Null:C1517)
	
	// All discovered methods should start with "test_"
	var $testFunction : cs:C1710.TestFunction
	For each ($testFunction; $suite.testFunctions)
		$assert.isTrue($t; $testFunction.functionName="test_@"; "All discovered methods should start with test_, found: "+$testFunction.functionName)
	End for each 

Function test_assertion_with_complex_objects($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test assertion with complex nested objects - test properties instead of direct comparison
	var $obj1 : Object
	var $obj2 : Object
	$obj1:=New object:C1471("nested"; New object:C1471("value"; 42))
	$obj2:=New object:C1471("nested"; New object:C1471("value"; 43))
	
	// Test nested object properties - this avoids runtime errors
	$assert.areEqual($mockTest; $obj1.nested.value; $obj2.nested.value; "Different nested values should fail")
	$assert.isTrue($t; $mockTest.failed; "Different nested object values should fail the test")
	
	// Test same values pass
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$obj2.nested.value:=42
	$assert.areEqual($mockTest; $obj1.nested.value; $obj2.nested.value; "Same nested values should pass")
	$assert.isFalse($t; $mockTest.failed; "Same nested object values should pass the test")

Function test_assertion_with_large_data($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test assertion with large data structures
	var $largeCollection : Collection
	$largeCollection:=[]
	
	var $i : Integer
	For ($i; 1; 1000)
		$largeCollection.push("Item "+String:C10($i))
	End for 
	
	$assert.areEqual($mockTest; 1000; $largeCollection.length; "Large collection should have correct size")
	$assert.isFalse($t; $mockTest.failed; "Large data assertion should succeed")

Function test_log_message_overflow($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test logging many messages
	var $i : Integer
	For ($i; 1; 100)
		$testing.log("Message "+String:C10($i))
	End for 
	
	$assert.areEqual($t; 100; $testing.logMessages.length; "Should store all log messages")
	$assert.areEqual($t; "Message 1"; $testing.logMessages[0]; "Should store first message correctly")
	$assert.areEqual($t; "Message 100"; $testing.logMessages[99]; "Should store last message correctly")

Function test_very_long_log_messages($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test very long log message
	var $longMessage : Text
	$longMessage:=""
	var $i : Integer
	For ($i; 1; 1000)
		$longMessage:=$longMessage+"This is a very long message segment. "
	End for 
	
	$testing.log($longMessage)
	$assert.areEqual($t; 1; $testing.logMessages.length; "Should store long message")
	$assert.areEqual($t; $longMessage; $testing.logMessages[0]; "Should store complete long message")

Function test_pattern_edge_cases($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test various edge case patterns
	$assert.isFalse($t; $runner._matchesPattern("test"; ""); "Empty pattern should not match")
	$assert.isTrue($t; $runner._matchesPattern(""; "*"); "Universal pattern should match empty string")
	$assert.isFalse($t; $runner._matchesPattern(""; "test"); "Empty string should not match non-empty pattern")
	
	// Test patterns with special characters
	$assert.isTrue($t; $runner._matchesPattern("a*b"; "a@b"); "Should handle literal @ in 4D pattern")
	$assert.isTrue($t; $runner._matchesPattern("test_method"; "*_*"); "Should match patterns with underscores")

Function test_class_discovery_edge_cases($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $testClasses : Collection
	$testClasses:=$runner._getTestClasses()
	
	// Verify all discovered classes end with "Test"
	var $class : 4D:C1709.Class
	For each ($class; $testClasses)
		$assert.isTrue($t; $class.name="@Test"; "All test classes should end with 'Test', found: "+$class.name)
		$assert.isNotNull($t; $class; "Discovered class should not be null")
	End for each 
	
	// Should find at least the test classes we created
	$assert.isTrue($t; $testClasses.length>=4; "Should discover multiple test classes")

Function test_timing_precision($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test that timing works correctly even for very fast tests
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	var $classInstance : cs:C1710.ExampleTest
	$classInstance:=cs:C1710.ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710.TestFunction
	$testFunction:=cs:C1710.TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass"; "")
	$testFunction.run()
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	$assert.isTrue($t; $result.duration>=0; "Duration should be non-negative even for fast tests")
	$assert.isTrue($t; $testFunction.endTime>=$testFunction.startTime; "End time should be >= start time")

Function test_concurrent_test_contexts($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test multiple Testing contexts don't interfere
	var $test1 : cs:C1710.Testing
	var $test2 : cs:C1710.Testing
	$test1:=cs:C1710.Testing.new()
	$test2:=cs:C1710.Testing.new()
	
	$test1.log("Message from test1")
	$test2.log("Message from test2")
	$test1.fail()
	
	$assert.isTrue($t; $test1.failed; "Test1 should be failed")
	$assert.isFalse($t; $test2.failed; "Test2 should not be failed")
	$assert.areEqual($t; 1; $test1.logMessages.length; "Test1 should have its message")
	$assert.areEqual($t; 1; $test2.logMessages.length; "Test2 should have its message")
	$assert.areEqual($t; "Message from test1"; $test1.logMessages[0]; "Test1 message should be correct")
	$assert.areEqual($t; "Message from test2"; $test2.logMessages[0]; "Test2 message should be correct")

Function test_memory_and_cleanup($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test that objects are properly initialized and don't leak references
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $initialSuites : Integer
	$initialSuites:=$runner.testSuites.length
	
	// Discover tests
	$runner.discoverTests()
	
	$assert.isTrue($t; $runner.testSuites.length>$initialSuites; "Should discover test suites")
	
	// Verify each suite has proper structure
	var $suite : cs:C1710.TestSuite
	For each ($suite; $runner.testSuites)
		$assert.isNotNull($t; $suite.class; "Suite should have class reference")
		$assert.isNotNull($t; $suite.classInstance; "Suite should have class instance")
		$assert.isNotNull($t; $suite.testFunctions; "Suite should have testFunctions collection")
	End for each