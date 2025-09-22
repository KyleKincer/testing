// Test class to verify error handling capabilities work correctly
Class constructor()

Function test_error_handler_initialization($t : cs:C1710.Testing)

        var $runner : cs:C1710.TestRunner
        $runner:=cs:C1710.TestRunner.new()
        $runner._prepareErrorHandlingStorage()

        // Verify that Storage.testErrors exists and can be initialized
        $t.assert.isNotNull($t; Storage:C1525.testErrors; "Error storage should be initialized")
        $t.assert.areEqual($t; Is collection:K8:32; Value type:C1509(Storage:C1525.testErrors); "Error storage should be a collection")

        // Ensure local process tracking is available
        $t.assert.isNotNull($t; Storage:C1525.testErrorHandlerProcesses; "Process tracking should be initialized")
        $t.assert.areEqual($t; Is collection:K8:32; Value type:C1509(Storage:C1525.testErrorHandlerProcesses); "Process tracking should be a collection")

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
                "timestamp"; Milliseconds:C459; \
                "processNumber"; 5; \
                "context"; "global"; \
                "isLocal"; False:C215\
                )

        // Verify the error structure has all required fields
        $t.assert.isNotNull($t; $errorInfo.code; "Error should have code field")
        $t.assert.isNotNull($t; $errorInfo.text; "Error should have text field")
        $t.assert.isNotNull($t; $errorInfo.method; "Error should have method field")
        $t.assert.isNotNull($t; $errorInfo.line; "Error should have line field")
        $t.assert.isNotNull($t; $errorInfo.timestamp; "Error should have timestamp field")
        $t.assert.areEqual($t; 5; $errorInfo.processNumber; "Error should store process number")
        $t.assert.areEqual($t; "global"; $errorInfo.context; "Error should store context")
        $t.assert.isFalse($t; $errorInfo.isLocal; "Global errors should not be marked local")
	
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

Function test_global_error_collection($t : cs:C1710.Testing)

        // Prepare shared error storage with a simulated global error
        Use (Storage:C1525)
                Storage:C1525.testErrors:=New shared collection:C1527
        End use

        var $globalError : Object
        $globalError:=New object:C1471(\
                "code"; 512; \
                "text"; "GlobalFailure"; \
                "method"; "DoSomething"; \
                "line"; 9; \
                "timestamp"; Milliseconds:C459; \
                "processNumber"; 42; \
                "context"; "global"; \
                "isLocal"; False:C215\
                )

        Use (Storage:C1525.testErrors)
                Storage:C1525.testErrors.push(OB Copy:C1225($globalError; ck shared:K85:29))
        End use

        var $runner : cs:C1710.TestRunner
        $runner:=cs:C1710.TestRunner.new()

        $runner._captureGlobalErrors()

        $t.assert.areEqual($t; 1; $runner.results.globalErrors.length; "Runner should capture global errors")
        $t.assert.isTrue($t; $runner.results.hasGlobalErrors; "Runner should flag presence of global errors")
        $t.assert.areEqual($t; 1; $runner.results.globalErrorCount; "Runner should count global errors")

        Use (Storage:C1525.testErrors)
                $t.assert.areEqual($t; 0; Storage:C1525.testErrors.length; "Global errors should be drained from storage")
        End use

Function test_register_process_tracking($t : cs:C1710.Testing)

        var $runner : cs:C1710.TestRunner
        $runner:=cs:C1710.TestRunner.new()
        $runner._prepareErrorHandlingStorage()

        var $processNumber : Integer
        $processNumber:=98765

        TestErrorHandlerRegisterProcess($processNumber)

        Use (Storage:C1525.testErrorHandlerProcesses)
                $t.assert.isTrue($t; Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)>=0; "Should register process for local error tracking")
        End use

        // Registering again should not duplicate entries
        TestErrorHandlerRegisterProcess($processNumber)

        Use (Storage:C1525.testErrorHandlerProcesses)
                var $occurrences : Integer
                $occurrences:=0
                var $index : Integer
                For ($index; 0; Storage:C1525.testErrorHandlerProcesses.length-1)
                        If (Storage:C1525.testErrorHandlerProcesses[$index]=$processNumber)
                                $occurrences+=1
                        End if
                End for
                $t.assert.areEqual($t; 1; $occurrences; "Process should only be tracked once")
        End use

        TestErrorHandlerUnregister($processNumber)

        Use (Storage:C1525.testErrorHandlerProcesses)
                $t.assert.isFalse($t; Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)>=0; "Should remove process from tracking after unregister")
        End use

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