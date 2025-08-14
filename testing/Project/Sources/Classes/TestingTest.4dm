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

Function test_run_method_placeholder($t : cs:C1710.Testing)
	
	var $testing : cs:C1710.Testing
	$testing:=cs:C1710.Testing.new()
	
	// Test that run method exists (even if not implemented)
	// This is a placeholder method in the current implementation
	$t.assert.isNotNull($t; $testing.run; "Run method should exist")
	
	// Call it to ensure it doesn't crash
	$testing.run("test"; Null:C1517)
	// Should not throw an error