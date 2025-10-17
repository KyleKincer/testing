// Test class for trigger configuration functionality
// #tags: unit

Class constructor()

// Tests for user parameter trigger control

Function test_defaultTriggerBehavior($t : cs.Testing)
	// Default behavior should disable triggers (testMode = true)
	var $runner : cs.TestRunner
	$runner:=cs.TestRunner.new(Null; Null; New object)

	$t.assert.isTrue($t; $runner.disableTriggersByDefault; "Triggers should be disabled by default")

Function test_triggersEnabledParameter($t : cs.Testing)
	// triggers=enabled should set testMode to false
	var $runner : cs.TestRunner
	$runner:=cs.TestRunner.new(Null; Null; New object("triggers"; "enabled"))

	$t.assert.isFalse($t; $runner.disableTriggersByDefault; "Triggers should be enabled when triggers=enabled")

Function test_triggersDisabledParameter($t : cs.Testing)
	// triggers=disabled should set testMode to true
	var $runner : cs.TestRunner
	$runner:=cs.TestRunner.new(Null; Null; New object("triggers"; "disabled"))

	$t.assert.isTrue($t; $runner.disableTriggersByDefault; "Triggers should be disabled when triggers=disabled")

// Tests for test-level trigger control via comments

Function test_triggerControlParsing_default($t : cs.Testing)
	// Test should parse default trigger control (no annotation)
	var $classCode : Text
	$classCode:="// No trigger control annotation\n"
	$classCode:=$classCode+"Function test_example($t : cs.Testing)\n"
	$classCode:=$classCode+"    // Function body\n"

	var $testFunc : cs._TestFunction
	$testFunc:=cs._TestFunction.new(cs._ExampleTest; cs._ExampleTest.new(); Formula(ALERT("test")); "test_example"; $classCode; Null)

	$t.assert.areEqual($t; "default"; $testFunc.triggerControl; "Should parse default trigger control")

// #triggers: enabled
Function test_triggerControlParsing_enabled($t : cs.Testing)
	// Test should parse enabled trigger control from real function
	// This function itself has #triggers: enabled annotation
	var $actualTriggerControl : Text

	// Parse this class's code and check this function
	var $classCode : Text
	var $path : Text
	$path:="[class]/TriggerConfigurationTest"
	METHOD GET CODE($path; $classCode; *)

	var $testFunc : cs._TestFunction
	$testFunc:=cs._TestFunction.new(cs.TriggerConfigurationTest; cs.TriggerConfigurationTest.new(); Formula(ALERT("test")); "test_triggerControlParsing_enabled"; $classCode; Null)

	$t.assert.areEqual($t; "enabled"; $testFunc.triggerControl; "Should parse enabled trigger control from real function")

// #triggers: disabled
Function test_triggerControlParsing_disabled($t : cs.Testing)
	// Test should parse disabled trigger control from real function
	// This function itself has #triggers: disabled annotation

	// Parse this class's code and check this function
	var $classCode : Text
	var $path : Text
	$path:="[class]/TriggerConfigurationTest"
	METHOD GET CODE($path; $classCode; *)

	var $testFunc : cs._TestFunction
	$testFunc:=cs._TestFunction.new(cs.TriggerConfigurationTest; cs.TriggerConfigurationTest.new(); Formula(ALERT("test")); "test_triggerControlParsing_disabled"; $classCode; Null)

	$t.assert.areEqual($t; "disabled"; $testFunc.triggerControl; "Should parse disabled trigger control from real function")

// Integration tests

Function test_storageInitializedWithDefaultBehavior($t : cs.Testing)
	// Storage should be initialized with default trigger behavior
	var $runner : cs.TestRunner
	$runner:=cs.TestRunner.new(Null; Null; New object)

	// Run initialization
	$runner._initializeTriggerControl()

	$t.assert.isNotNull($t; Storage.triggersDisabled; "Storage.triggersDisabled should exist")
	$t.assert.isTrue($t; Storage.triggersDisabled.testMode; "testMode should be true by default")

Function test_storageInitializedWithTriggersEnabled($t : cs.Testing)
	// Storage should be initialized with triggers enabled when specified
	var $runner : cs.TestRunner
	$runner:=cs.TestRunner.new(Null; Null; New object("triggers"; "enabled"))

	// Run initialization
	$runner._initializeTriggerControl()

	$t.assert.isNotNull($t; Storage.triggersDisabled; "Storage.triggersDisabled should exist")
	$t.assert.isFalse($t; Storage.triggersDisabled.testMode; "testMode should be false when triggers=enabled")

Function test_restoreDefaultTriggerBehavior($t : cs.Testing)
	// Should restore default behavior after changing it
	var $runner : cs.TestRunner
	$runner:=cs.TestRunner.new(Null; Null; New object)  // Default: disabled
	$runner._initializeTriggerControl()

	// Enable triggers temporarily
	$runner.enableTriggersForTest()
	$t.assert.isFalse($t; Storage.triggersDisabled.testMode; "testMode should be false after enabling")

	// Restore default
	$runner.restoreDefaultTriggerBehavior()
	$t.assert.isTrue($t; Storage.triggersDisabled.testMode; "testMode should be restored to default (true)")
