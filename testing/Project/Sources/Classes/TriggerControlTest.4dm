// #tags: unit
// Tests for trigger control functionality during test execution

Class constructor()

Function test_storageTriggersDisabledExists($t : cs.Testing)
	// Verify that Storage.triggersDisabled exists
	$t.assert.isNotNull($t; Storage:C1525.triggersDisabled; "Storage.triggersDisabled should exist")

Function test_testModeFlagIsSet($t : cs.Testing)
	// Verify that testMode flag is set to True during tests
	$t.assert.isTrue($t; Storage:C1525.triggersDisabled.testMode; "Storage.triggersDisabled.testMode should be True")

Function test_testModeFlagIsBoolean($t : cs.Testing)
	// Verify that testMode is a boolean value
	var $testMode : Variant
	$testMode:=Storage:C1525.triggersDisabled.testMode
	$t.assert.areEqual($t; Is boolean:K8:9; Value type:C1509($testMode); "testMode should be a boolean type")

Function test_triggerCheckPattern($t : cs.Testing)
	// Test the pattern that triggers would use to check if they should skip
	var $shouldSkip : Boolean

	// This is the pattern documented for use in triggers
	$shouldSkip:=(Storage:C1525.triggersDisabled#Null:C1517) && (Storage:C1525.triggersDisabled.testMode=True:C214)

	$t.assert.isTrue($t; $shouldSkip; "Trigger skip pattern should evaluate to True during tests")

Function test_storageAccessibleInFormula($t : cs.Testing)
	// Verify Storage flag is accessible from within a Formula (simulates trigger context)
	var $formula : 4D:C1709.Function
	var $result : Boolean

	$formula:=Formula:C1597((Storage:C1525.triggersDisabled#Null:C1517) && (Storage:C1525.triggersDisabled.testMode=True:C214))
	$result:=$formula.call()

	$t.assert.isTrue($t; $result; "Storage flag should be accessible from Formula context")
