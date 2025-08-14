property testData : Object
property setupCalled : Boolean
property teardownCalled : Boolean
property beforeEachCount : Integer
property afterEachCount : Integer

Class constructor()
	This:C1470.testData:=New object:C1471
	This:C1470.setupCalled:=False:C215
	This:C1470.teardownCalled:=False:C215
	This:C1470.beforeEachCount:=0
	This:C1470.afterEachCount:=0

Function setup()
	// Called once before all tests in this suite
	This:C1470.setupCalled:=True:C214
	This:C1470.testData.connection:="database_connection"
	This:C1470.testData.users:=[]

Function teardown()
	// Called once after all tests in this suite
	This:C1470.teardownCalled:=True:C214
	This:C1470.testData:=Null:C1517

Function beforeEach()
	// Called before each individual test
	This:C1470.beforeEachCount:=This:C1470.beforeEachCount+1
	This:C1470.testData.currentTest:="test_"+String:C10(This:C1470.beforeEachCount)

Function afterEach()
	// Called after each individual test
	This:C1470.afterEachCount:=This:C1470.afterEachCount+1
	This:C1470.testData.currentTest:=""

Function test_setup_was_called($t : cs:C1710.Testing)
	$t.assert.isTrue($t; This:C1470.setupCalled; "Setup should have been called")
	$t.assert.isNotNull($t; This:C1470.testData.connection; "Setup should have initialized connection")

Function test_beforeEach_was_called($t : cs:C1710.Testing)
	$t.assert.isTrue($t; This:C1470.beforeEachCount>0; "BeforeEach should have been called")
	$t.assert.areEqual($t; "test_"+String:C10(This:C1470.beforeEachCount); This:C1470.testData.currentTest; "BeforeEach should set current test")

Function test_data_is_available($t : cs:C1710.Testing)
	$t.assert.isNotNull($t; This:C1470.testData; "Test data should be available")
	$t.assert.areEqual($t; "database_connection"; This:C1470.testData.connection; "Connection should be set by setup")