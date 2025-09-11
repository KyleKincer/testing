// Comprehensive tests for Testing class functionality
Class constructor()

Function test_testing_initialization($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	$t.assert.isNotNull($t; $testing; "Testing should initialize")
	$t.assert.isFalse($t; $testing.failed; "Should start as not failed")
	$t.assert.isFalse($t; $testing.done; "Should start as not done")
	$t.assert.isNotNull($t; $testing.logMessages; "Should initialize logMessages collection")
	$t.assert.areEqual($t; 0; $testing.logMessages.length; "Should start with empty log messages")

Function test_log_message_collection($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test logging single message
	$testing.log("First message")
	$t.assert.areEqual($t; 1; $testing.logMessages.length; "Should have one message")
	$t.assert.areEqual($t; "First message"; $testing.logMessages[0]; "Should store correct message")
	
	// Test logging multiple messages
	$testing.log("Second message")
	$testing.log("Third message")
	$t.assert.areEqual($t; 3; $testing.logMessages.length; "Should have three messages")
	$t.assert.areEqual($t; "Second message"; $testing.logMessages[1]; "Should store messages in order")
	$t.assert.areEqual($t; "Third message"; $testing.logMessages[2]; "Should store messages in order")

Function test_log_empty_messages($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test logging empty string
	$testing.log("")
	$t.assert.areEqual($t; 1; $testing.logMessages.length; "Should log empty string")
	$t.assert.areEqual($t; ""; $testing.logMessages[0]; "Should store empty string")

Function test_fail_method($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test fail method
	$testing.fail()
	$t.assert.isTrue($t; $testing.failed; "Should mark as failed")
	$t.assert.isFalse($t; $testing.done; "Should not mark as done unless fatal")

Function test_fatal_method($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test fatal method
	$testing.fatal()
	$t.assert.isTrue($t; $testing.failed; "Should mark as failed")
	$t.assert.isTrue($t; $testing.done; "Should mark as done")

Function test_state_persistence($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test that state persists across operations
	$testing.log("Message 1")
	$testing.fail()
	$testing.log("Message 2")
	
	$t.assert.isTrue($t; $testing.failed; "Should remain failed")
	$t.assert.areEqual($t; 2; $testing.logMessages.length; "Should accumulate messages after failure")

Function test_multiple_fail_calls($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test multiple fail calls
	$testing.fail()
	$testing.fail()
	$testing.fail()
	
	$t.assert.isTrue($t; $testing.failed; "Should remain failed after multiple calls")

Function test_fail_after_fatal($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test behavior after fatal
	$testing.fatal()
	$testing.fail()  // Should still work
	$testing.log("After fatal")
	
	$t.assert.isTrue($t; $testing.failed; "Should remain failed")
	$t.assert.isTrue($t; $testing.done; "Should remain done")
	$t.assert.areEqual($t; 1; $testing.logMessages.length; "Should still accept log messages")

Function test_log_with_special_characters($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test logging messages with special characters
	$testing.log("Message with \"quotes\"")
	$testing.log("Message with\nnewlines")
	$testing.log("Message with\ttabs")
	
	$t.assert.areEqual($t; 3; $testing.logMessages.length; "Should handle special characters")
	$t.assert.areEqual($t; "Message with \"quotes\""; $testing.logMessages[0]; "Should preserve quotes")
	$t.assert.areEqual($t; "Message with\nnewlines"; $testing.logMessages[1]; "Should preserve newlines")
	$t.assert.areEqual($t; "Message with\ttabs"; $testing.logMessages[2]; "Should preserve tabs")

Function test_run_executes_subtest($t : cs:C1710.Testing)

        var $testing : cs:C1710.Testing
        $testing:=cs:C1710.Testing.new()

        var $result : Boolean
        $result:=$testing.run("sub"; Formula($1.log("ran")))

        $t.assert.isTrue($t; $result; "Run should return true when subtest passes")
        $t.assert.areEqual($t; 1; $testing.logMessages.length; "Parent should capture subtest log")
        $t.assert.areEqual($t; "sub: ran"; $testing.logMessages[0]; "Log should be prefixed with subtest name")

Function test_run_propagates_failure($t : cs:C1710.Testing)

        var $testing : cs:C1710.Testing
        $testing:=cs:C1710.Testing.new()

        var $result : Boolean
        $result:=$testing.run("fail"; Formula($1.fail()))

        $t.assert.isFalse($t; $result; "Run should return false when subtest fails")
        $t.assert.isTrue($t; $testing.failed; "Parent test should be marked as failed")


Function test_run_uses_parent_context($t : cs:C1710.Testing)

        // Verify that subtests execute with the same object context as the parent
        This.contextValue:="parent"

        $t.run("ctx"; This._setContextChild)

        $t.assert.areEqual($t; "child"; This.contextValue; "Subtest should run with parent This context")

Function _setContextChild($t : cs:C1710.Testing)

        $t.log("running")
        This.contextValue:="child"

Function test_run_with_data_argument($t : cs:C1710.Testing)

        var $testing : cs:C1710.Testing
        $testing:=cs:C1710.Testing.new()

        var $cases : Collection
        $cases:=[\
                New object("name"; "ok"; "in"; 1; "want"; 2);\
                New object("name"; "bad"; "in"; 2; "want"; 4)\
        ]

        var $case : Object
        For each ($case; $cases)
                $testing.run($case.name; This._addOneCase; $case)
        End for each

        $t.assert.areEqual($t; 2; $testing.logMessages.length; "Should log each case")
        $t.assert.areEqual($t; "ok: 2"; $testing.logMessages[0]; "Should prefix log with case name")
        $t.assert.areEqual($t; "bad: 3"; $testing.logMessages[1]; "Should prefix log with case name")
        $t.assert.isTrue($t; $testing.failed; "Parent should fail if any case fails")

Function test_run_subtest_stats_isolated($t : cs:C1710.Testing)

        var $testing : cs:C1710.Testing
        $testing:=cs:C1710.Testing.new()

        // First subtest records a stat
        $testing.run("first"; Formula($1.stats.mock("mocked"; []; Null)))

        // Second subtest should start with fresh stats
        $testing.run("second"; Formula($1.assert.areEqual($1; 0; $1.stats.getStat("mocked").getNumberOfCalls(); "Stats should not carry over between subtests")))

        // Parent stats should remain unaffected
        var $parentStat : cs:C1710._UnitStatsDetail
        $parentStat:=$testing.stats.getStat("mocked")
        $t.assert.areEqual($t; 0; $parentStat.getNumberOfCalls(); "Parent stats should remain unaffected")

Function _addOneCase($t : cs:C1710.Testing; $case : Object)

        var $got : Integer
        $got:=$case.in+1
        $t.log(String($got))
        If ($got#$case.want)
                $t.fail()
        End if

