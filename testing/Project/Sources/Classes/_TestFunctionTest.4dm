// Comprehensive tests for TestFunction functionality
Class constructor()

Function test_test_function_initialization($t : cs:C1710.Testing)
	
	// Create a TestFunction for a specific test method
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	
	$t.assert.isNotNull($t; $testFunction; "TestFunction should initialize")
	$t.assert.areEqual($t; "test_areEqual_pass"; $testFunction.functionName; "Should store function name")
	$t.assert.isNotNull($t; $testFunction.t; "Should create Testing context")
	$t.assert.isNotNull($t; $testFunction.runtimeErrors; "Should initialize runtime errors collection")
	$t.assert.areEqual($t; 0; $testFunction.runtimeErrors.length; "Runtime errors should be empty initially")

Function test_test_function_execution($t : cs:C1710.Testing)
	
	// Create and run a test function
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	
	// Run the test
	$testFunction.run()
	
	// Check timing was recorded
	$t.assert.isTrue($t; $testFunction.startTime>0; "Should record start time")
	$t.assert.isTrue($t; $testFunction.endTime>0; "Should record end time")
	$t.assert.isTrue($t; $testFunction.endTime>=$testFunction.startTime; "End time should be >= start time")

Function test_test_result_object_creation($t : cs:C1710.Testing)
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	$testFunction.run()
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	$t.assert.isNotNull($t; $result; "Should return result object")
	$t.assert.areEqual($t; "test_areEqual_pass"; $result.name; "Should include test name")
	$t.assert.areEqual($t; "_ExampleTest"; $result.suite; "Should include suite name")
	$t.assert.isNotNull($t; $result.passed; "Should include passed status")
	$t.assert.isNotNull($t; $result.failed; "Should include failed status")
	$t.assert.isNotNull($t; $result.duration; "Should include duration")
	$t.assert.isNotNull($t; $result.runtimeErrors; "Should include runtime errors")
	$t.assert.isNotNull($t; $result.logMessages; "Should include log messages")

Function test_successful_test_result($t : cs:C1710.Testing)
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	$testFunction.run()
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	$t.assert.isTrue($t; $result.passed; "Successful test should be marked as passed")
	$t.assert.isFalse($t; $result.failed; "Successful test should not be marked as failed")
	$t.assert.areEqual($t; 0; $result.runtimeErrors.length; "Successful test should have no runtime errors")

Function test_duration_calculation($t : cs:C1710.Testing)
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	$testFunction.run()
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	$t.assert.isTrue($t; $result.duration>=0; "Duration should be non-negative")
	$t.assert.areEqual($t; $testFunction.endTime-$testFunction.startTime; $result.duration; "Duration should match time difference")

Function test_runtime_error_storage($t : cs:C1710.Testing)
	
	// Test that runtime errors are properly stored
	// Create a proper TestFunction with valid parameters
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_example")
	
	// Run the test first to initialize timing properties
	$testFunction.run()
	
	// Manually add a runtime error to test the storage
	var $mockError : Object
	$mockError:=New object:C1471("code"; -1; "text"; "Mock error"; "method"; "test_example"; "line"; 1; "timestamp"; Milliseconds:C459)
	$testFunction.runtimeErrors.push($mockError)
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	$t.assert.areEqual($t; 1; $result.runtimeErrors.length; "Should store runtime errors")
	$t.assert.areEqual($t; "Mock error"; $result.runtimeErrors[0].text; "Should store error details")

Function test_testing_context_integration($t : cs:C1710.Testing)
	
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	
	// Test that Testing context is properly initialized
	$t.assert.isFalse($t; $testFunction.t.failed; "Testing context should start as not failed")
	$t.assert.isFalse($t; $testFunction.t.done; "Testing context should start as not done")
	$t.assert.areEqual($t; 0; $testFunction.t.logMessages.length; "Testing context should start with no log messages")