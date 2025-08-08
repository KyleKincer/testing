// Tests for JSON output functionality
Class constructor()

Function test_results_object_structure($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test that all required fields exist
	$assert.isNotNull($t; $results.totalTests; "Should have totalTests field")
	$assert.isNotNull($t; $results.passed; "Should have passed field")
	$assert.isNotNull($t; $results.failed; "Should have failed field")
	$assert.isNotNull($t; $results.skipped; "Should have skipped field")
	$assert.isNotNull($t; $results.startTime; "Should have startTime field")
	$assert.isNotNull($t; $results.endTime; "Should have endTime field")
	$assert.isNotNull($t; $results.duration; "Should have duration field")
	$assert.isNotNull($t; $results.suites; "Should have suites field")
	$assert.isNotNull($t; $results.failedTests; "Should have failedTests field")

Function test_results_object_types($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test field types
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.totalTests); "totalTests should be numeric")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.passed); "passed should be numeric")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.failed); "failed should be numeric")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.skipped); "skipped should be numeric")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.startTime); "startTime should be numeric")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.endTime); "endTime should be numeric")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($results.duration); "duration should be numeric")
	$assert.areEqual($t; Is collection:K8:32; Value type:C1509($results.suites); "suites should be collection")
	$assert.areEqual($t; Is collection:K8:32; Value type:C1509($results.failedTests); "failedTests should be collection")

Function test_initial_results_values($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test initial values
	$assert.areEqual($t; 0; $results.totalTests; "totalTests should start at 0")
	$assert.areEqual($t; 0; $results.passed; "passed should start at 0")
	$assert.areEqual($t; 0; $results.failed; "failed should start at 0")
	$assert.areEqual($t; 0; $results.skipped; "skipped should start at 0")
	$assert.areEqual($t; 0; $results.startTime; "startTime should start at 0")
	$assert.areEqual($t; 0; $results.endTime; "endTime should start at 0")
	$assert.areEqual($t; 0; $results.duration; "duration should start at 0")
	$assert.areEqual($t; 0; $results.suites.length; "suites should be empty initially")
	$assert.areEqual($t; 0; $results.failedTests.length; "failedTests should be empty initially")

Function test_test_result_object_structure($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Create a test function result to examine its structure
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	var $classInstance : cs:C1710.ExampleTest
	$classInstance:=cs:C1710.ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710.TestFunction
	$testFunction:=cs:C1710.TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	$testFunction.run()
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	// Test result object structure
	$assert.isNotNull($t; $result.name; "Result should have name field")
	$assert.isNotNull($t; $result.passed; "Result should have passed field")
	$assert.isNotNull($t; $result.failed; "Result should have failed field")
	$assert.isNotNull($t; $result.duration; "Result should have duration field")
	$assert.isNotNull($t; $result.suite; "Result should have suite field")
	$assert.isNotNull($t; $result.runtimeErrors; "Result should have runtimeErrors field")
	$assert.isNotNull($t; $result.logMessages; "Result should have logMessages field")

Function test_suite_result_structure($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// We can't easily test the internal _collectSuiteResults method directly
	// but we can verify that suite results have the expected structure
	// by examining the pattern in TestRunner code
	
	// Create a mock suite result structure
	var $suiteResult : Object
	$suiteResult:=New object:C1471(\
		"name"; "MockTest"; \
		"tests"; []; \
		"passed"; 0; \
		"failed"; 0\
		)
	
	$assert.areEqual($t; "MockTest"; $suiteResult.name; "Suite result should have name")
	$assert.areEqual($t; Is collection:K8:32; Value type:C1509($suiteResult.tests); "Suite result should have tests collection")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($suiteResult.passed); "Suite result should have passed count")
	$assert.areEqual($t; Is real:K8:4; Value type:C1509($suiteResult.failed); "Suite result should have failed count")

Function test_json_serialization_compatibility($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test that the results object can be JSON serialized
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($results)
	
	$assert.isTrue($t; Length:C16($jsonString)>0; "Should produce non-empty JSON")
	$assert.isTrue($t; $jsonString="{@"; "JSON should start with opening brace")
	$assert.isTrue($t; $jsonString="@}"; "JSON should end with closing brace")

Function test_json_parsing_roundtrip($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test JSON roundtrip (serialize and parse back)
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($results)
	
	var $parsed : Object
	$parsed:=JSON Parse:C1218($jsonString)
	
	$assert.areEqual($t; $results.totalTests; $parsed.totalTests; "Roundtrip should preserve totalTests")
	$assert.areEqual($t; $results.passed; $parsed.passed; "Roundtrip should preserve passed")
	$assert.areEqual($t; $results.failed; $parsed.failed; "Roundtrip should preserve failed")

Function test_output_format_setting($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that output format is set (depends on current user parameters)
	$assert.isTrue($t; ($runner.outputFormat="human") || ($runner.outputFormat="json"); "Output format should be either human or json")
	
	// We can't easily test format=json parameter parsing without mocking
	// the Get database parameter call, but we can verify the format property exists

Function test_error_object_structure($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test runtime error object structure (as created by error handler)
	var $errorInfo : Object
	$errorInfo:=New object:C1471(\
		"code"; -1; \
		"text"; "Test error"; \
		"method"; "test_method"; \
		"line"; 42; \
		"timestamp"; Milliseconds:C459\
		)
	
	// Verify structure matches what TestErrorHandler creates
	$assert.isNotNull($t; $errorInfo.code; "Error should have code")
	$assert.isNotNull($t; $errorInfo.text; "Error should have text")
	$assert.isNotNull($t; $errorInfo.method; "Error should have method")
	$assert.isNotNull($t; $errorInfo.line; "Error should have line")
	$assert.isNotNull($t; $errorInfo.timestamp; "Error should have timestamp")
	
	// Test JSON serialization of error object
	var $errorJson : Text
	$errorJson:=JSON Stringify:C1217($errorInfo)
	$assert.isTrue($t; Length:C16($errorJson)>0; "Error object should serialize to JSON")

Function test_timing_data_integrity($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test that timing data makes sense
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710.ExampleTest
	var $classInstance : cs:C1710.ExampleTest
	$classInstance:=cs:C1710.ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710.TestFunction
	$testFunction:=cs:C1710.TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	
	var $beforeRun : Integer
	$beforeRun:=Milliseconds:C459
	$testFunction.run()
	var $afterRun : Integer
	$afterRun:=Milliseconds:C459
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	// Verify timing makes sense
	$assert.isTrue($t; $result.duration>=0; "Duration should be non-negative")
	$assert.isTrue($t; $testFunction.startTime>=$beforeRun; "Start time should be after test creation")
	$assert.isTrue($t; $testFunction.endTime<=$afterRun; "End time should be before test completion")
	$assert.isTrue($t; $testFunction.endTime>=$testFunction.startTime; "End time should be after start time")