// Test class to verify error handling capabilities work correctly
Class constructor()

Function test_error_handler_initialization($t : cs:C1710.Testing)
	
        // Verify that per-process error storage exists and can be initialized
        var $processId : Text
        $processId:=String:C10(Current process:C322)

        Use (Storage:C1525)
                If (Storage:C1525.testErrorsByProcess=Null:C1517)
                        Storage:C1525.testErrorsByProcess:=New shared object:C1526
                End if
                If (Storage:C1525.testErrorsByProcess[$processId]=Null:C1517)
                        Storage:C1525.testErrorsByProcess[$processId]:=New shared collection:C1527
                End if
        End use

        $t.assert.isNotNull($t; Storage:C1525.testErrorsByProcess[$processId]; "Error storage should be initialized")
        $t.assert.areEqual($t; Is collection:K8:32; Value type:C1509(Storage:C1525.testErrorsByProcess[$processId]); "Error storage should be a collection")

Function test_error_information_structure($t : cs:C1710.Testing)
	
	// Create a mock error info structure like the error handler would
	var $errorInfo : Object
	var $errorCode : Integer
	var $errorLine : Integer
	$errorCode:=-10716
	$errorLine:=42
	$errorInfo:=New object:C1471(\
		"code"; $errorCode; \
		"text"; "TestMethod"; \
		"method"; "someFormula"; \
		"line"; $errorLine; \
		"timestamp"; Milliseconds:C459\
		)
	
	// Verify the error structure has all required fields
	$t.assert.isNotNull($t; $errorInfo.code; "Error should have code field")
	$t.assert.isNotNull($t; $errorInfo.text; "Error should have text field")
	$t.assert.isNotNull($t; $errorInfo.method; "Error should have method field")
	$t.assert.isNotNull($t; $errorInfo.line; "Error should have line field")
	$t.assert.isNotNull($t; $errorInfo.timestamp; "Error should have timestamp field")
	
	// Verify data types - 4D may store integers as reals in objects
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($errorInfo.code); "Error code should be real")
	$t.assert.areEqual($t; Is text:K8:3; Value type:C1509($errorInfo.text); "Error text should be text")
	$t.assert.areEqual($t; Is real:K8:4; Value type:C1509($errorInfo.line); "Error line should be real")

Function test_method_called_on_error_setup($t : cs:C1710.Testing)
	
	// Verify that Method called on error can be queried
	var $currentHandler : Text
	$currentHandler:=Method called on error:C704
	
	// The current handler should be either empty or "TestErrorHandler"
	$t.assert.isTrue($t; ($currentHandler="") || ($currentHandler="TestErrorHandler"); "Method called on error should be manageable")

Function test_testing_context_properties($t : cs:C1710.Testing)
	
	// Verify the testing context has expected properties
	$t.assert.isNotNull($t; $t; "Test context should exist")
	$t.assert.areEqual($t; Is boolean:K8:9; Value type:C1509($t.failed); "Test context should have failed boolean")
	$t.assert.areEqual($t; Is boolean:K8:9; Value type:C1509($t.done); "Test context should have done boolean")
	$t.assert.areEqual($t; Is collection:K8:32; Value type:C1509($t.logMessages); "Test context should have logMessages collection")
	
	// Initially the test should not be failed
	$t.assert.isFalse($t; $t.failed; "Test should not be failed initially")

Function test_assertion_failure_handling($t : cs:C1710.Testing)
	
	// Create a separate testing context to test failure handling
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Verify initial state
	$t.assert.isFalse($t; $mockTest.failed; "Mock test should start as not failed")
	$t.assert.areEqual($t; 0; $mockTest.logMessages.length; "Mock test should start with no log messages")
	
	// Trigger a failure
	$mockTest.fail()
	$t.assert.isTrue($t; $mockTest.failed; "Mock test should be marked as failed after fail() call")
	
	// Test logging
	$mockTest.log("Test failure message")
	$t.assert.areEqual($t; 1; $mockTest.logMessages.length; "Mock test should have one log message")
	$t.assert.areEqual($t; "Test failure message"; $mockTest.logMessages[0]; "Log message should be stored correctly")