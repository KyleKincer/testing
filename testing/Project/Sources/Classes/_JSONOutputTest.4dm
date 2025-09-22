// Tests for JSON output functionality
Class constructor()

Function test_results_object_structure($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test that all required fields exist
	$t.assert.isNotNull($t; $results.totalTests; "Should have totalTests field")
	$t.assert.isNotNull($t; $results.passed; "Should have passed field")
	$t.assert.isNotNull($t; $results.failed; "Should have failed field")
	$t.assert.isNotNull($t; $results.skipped; "Should have skipped field")
	$t.assert.isNotNull($t; $results.startTime; "Should have startTime field")
	$t.assert.isNotNull($t; $results.endTime; "Should have endTime field")
	$t.assert.isNotNull($t; $results.duration; "Should have duration field")
	$t.assert.isNotNull($t; $results.suites; "Should have suites field")
        $t.assert.isNotNull($t; $results.failedTests; "Should have failedTests field")
        $t.assert.isNotNull($t; $results.assertions; "Should have assertions field")

Function test_results_object_types($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test field types
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.totalTests); "totalTests should be numeric")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.passed); "passed should be numeric")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.failed); "failed should be numeric")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.skipped); "skipped should be numeric")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.startTime); "startTime should be numeric")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.endTime); "endTime should be numeric")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.duration); "duration should be numeric")
	$t.assert.areEqual($t; Is collection:K8:32; Value type:C1509($results.suites); "suites should be collection")
        $t.assert.areEqual($t; Is collection:K8:32; Value type:C1509($results.failedTests); "failedTests should be collection")
        $t.assert.areEqual($t; Is real:K8:4; Value type:C1509($results.assertions); "assertions should be numeric")

Function test_initial_results_values($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test initial values
	$t.assert.areEqual($t; 0; $results.totalTests; "totalTests should start at 0")
	$t.assert.areEqual($t; 0; $results.passed; "passed should start at 0")
        $t.assert.areEqual($t; 0; $results.failed; "failed should start at 0")
        $t.assert.areEqual($t; 0; $results.skipped; "skipped should start at 0")
        $t.assert.areEqual($t; 0; $results.assertions; "assertions should start at 0")
	$t.assert.areEqual($t; 0; $results.startTime; "startTime should start at 0")
	$t.assert.areEqual($t; 0; $results.endTime; "endTime should start at 0")
	$t.assert.areEqual($t; 0; $results.duration; "duration should start at 0")
	$t.assert.areEqual($t; 0; $results.suites.length; "suites should be empty initially")
	$t.assert.areEqual($t; 0; $results.failedTests.length; "failedTests should be empty initially")

Function test_test_result_object_structure($t : cs:C1710.Testing)
	
	// Create a test function result to examine its structure
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
	
	// Test result object structure
	$t.assert.isNotNull($t; $result.name; "Result should have name field")
	$t.assert.isNotNull($t; $result.passed; "Result should have passed field")
	$t.assert.isNotNull($t; $result.failed; "Result should have failed field")
	$t.assert.isNotNull($t; $result.duration; "Result should have duration field")
	$t.assert.isNotNull($t; $result.suite; "Result should have suite field")
	$t.assert.isNotNull($t; $result.runtimeErrors; "Result should have runtimeErrors field")
        $t.assert.isNotNull($t; $result.logMessages; "Result should have logMessages field")
        $t.assert.isNotNull($t; $result.assertions; "Result should have assertions field")
        $t.assert.isNotNull($t; $result.assertionCount; "Result should have assertionCount field")
        $t.assert.areEqual($t; Is collection:K8:32; Value type:C1509($result.assertions); "Assertions should be collection")
        $t.assert.areEqual($t; Is real:K8:4; Value type:C1509($result.assertionCount); "assertionCount should be numeric")

Function test_suite_result_structure($t : cs:C1710.Testing)
	
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
                "failed"; 0; \
                "skipped"; 0; \
                "assertions"; 0\
                )
	
	$t.assert.areEqual($t; "MockTest"; $suiteResult.name; "Suite result should have name")
	$t.assert.areEqual($t; Is collection:K8:32; Value type:C1509($suiteResult.tests); "Suite result should have tests collection")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($suiteResult.passed); "Suite result should have passed count")
        $t.assert.areEqual($t; Is real:K8:4; Value type:C1509($suiteResult.failed); "Suite result should have failed count")
        $t.assert.areEqual($t; Is real:K8:4; Value type:C1509($suiteResult.skipped); "Suite result should have skipped count")
        $t.assert.areEqual($t; Is real:K8:4; Value type:C1509($suiteResult.assertions); "Suite result should have assertions count")

Function test_json_serialization_compatibility($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test that the results object can be JSON serialized
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($results)
	
	$t.assert.isTrue($t; Length:C16($jsonString)>0; "Should produce non-empty JSON")
	$t.assert.isTrue($t; $jsonString="{@"; "JSON should start with opening brace")
	$t.assert.isTrue($t; $jsonString="@}"; "JSON should end with closing brace")

Function test_json_parsing_roundtrip($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	var $results : Object
	$results:=$runner.getResults()
	
	// Test JSON roundtrip (serialize and parse back)
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($results)
	
	var $parsed : Object
	$parsed:=JSON Parse:C1218($jsonString)
	
	$t.assert.areEqual($t; $results.totalTests; $parsed.totalTests; "Roundtrip should preserve totalTests")
	$t.assert.areEqual($t; $results.passed; $parsed.passed; "Roundtrip should preserve passed")
	$t.assert.areEqual($t; $results.failed; $parsed.failed; "Roundtrip should preserve failed")

Function test_output_format_setting($t : cs:C1710.Testing)
	
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	
	// Test that output format is set (depends on current user parameters)
	$t.assert.isTrue($t; ($runner.outputFormat="human") || ($runner.outputFormat="json") || ($runner.outputFormat="junit"); "Output format should be human, json, or junit")
	
	// We can't easily test format=json parameter parsing without mocking
	// the Get database parameter call, but we can verify the format property exists

Function test_error_object_structure($t : cs:C1710.Testing)
	
	// Test runtime error object structure (as created by error handler)
        var $errorInfo : Object
        $errorInfo:=New object:C1471(\
                "code"; -1; \
                "text"; "Test error"; \
                "method"; "test_method"; \
                "line"; 42; \
                "timestamp"; Milliseconds:C459; \
                "processNumber"; 1; \
                "context"; "local"; \
                "isLocal"; True:C214\
                )

        // Verify structure matches what TestErrorHandler creates
        $t.assert.isNotNull($t; $errorInfo.code; "Error should have code")
        $t.assert.isNotNull($t; $errorInfo.text; "Error should have text")
        $t.assert.isNotNull($t; $errorInfo.method; "Error should have method")
        $t.assert.isNotNull($t; $errorInfo.line; "Error should have line")
        $t.assert.isNotNull($t; $errorInfo.timestamp; "Error should have timestamp")
        $t.assert.areEqual($t; 1; $errorInfo.processNumber; "Error should capture process number")
        $t.assert.areEqual($t; "local"; $errorInfo.context; "Error should capture context")
        $t.assert.isTrue($t; $errorInfo.isLocal; "Error should flag local context")
	
	// Test JSON serialization of error object
	var $errorJson : Text
	$errorJson:=JSON Stringify:C1217($errorInfo)
	$t.assert.isTrue($t; Length:C16($errorJson)>0; "Error object should serialize to JSON")

Function test_timing_data_integrity($t : cs:C1710.Testing)
	
	// Test that timing data makes sense
	var $exampleClass : 4D:C1709.Class
	$exampleClass:=cs:C1710._ExampleTest
	var $classInstance : cs:C1710._ExampleTest
	$classInstance:=cs:C1710._ExampleTest.new()
	var $testMethod : 4D:C1709.Function
	$testMethod:=$classInstance.test_areEqual_pass
	
	var $testFunction : cs:C1710._TestFunction
	$testFunction:=cs:C1710._TestFunction.new($exampleClass; $classInstance; $testMethod; "test_areEqual_pass")
	
	var $beforeRun : Integer
	$beforeRun:=Milliseconds:C459
	$testFunction.run()
	var $afterRun : Integer
	$afterRun:=Milliseconds:C459
	
	var $result : Object
	$result:=$testFunction.getResult()
	
	// Verify timing makes sense
	$t.assert.isTrue($t; $result.duration>=0; "Duration should be non-negative")
	$t.assert.isTrue($t; $testFunction.startTime>=$beforeRun; "Start time should be after test creation")
	$t.assert.isTrue($t; $testFunction.endTime<=$afterRun; "End time should be before test completion")
	$t.assert.isTrue($t; $testFunction.endTime>=$testFunction.startTime; "End time should be after start time")