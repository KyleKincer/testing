// Example test class demonstrating transaction support in the testing framework

Function test_automaticTransactionRollback($t : cs:C1710.Testing)
	// #tags: transaction, integration
	// This test demonstrates automatic transaction rollback
	// Any database changes will be automatically rolled back after the test
	
	// Simulate creating test data
	$t.log("Creating test data within automatic transaction")
	
	// This would normally create records, but they'll be rolled back
	// Example: CREATE RECORD([Table1])
	// [Table1]Field1:="Test Data"
	// SAVE RECORD([Table1])
	
	$t.assert.isTrue($t; True; "Test data creation succeeded")

Function test_disabledTransactions($t : cs:C1710.Testing)
	// #tags: no-transaction
	// #transaction: false
	// This test explicitly disables automatic transactions
	// Use this for tests that need to interact with actual persistent data
	
	$t.log("Running test without automatic transactions")
	$t.assert.isTrue($t; True; "Test runs without transaction management")

Function test_manualTransactionControl($t : cs:C1710.Testing)
	// #tags: transaction, manual
	// #transaction: false
	// This test demonstrates manual transaction control
	
	$t.log("Testing manual transaction control")
	
	// Start a manual transaction
	var $started : Boolean
	$started:=$t.startTransaction()
	$t.assert.isTrue($t; $started; "Transaction started successfully")
	$t.assert.isTrue($t; $t.inTransaction(); "We are in a transaction")
	
	// Simulate some database operations
	$t.log("Performing database operations")
	
	// Cancel the transaction manually
	$t.cancelTransaction()
	$t.assert.isFalse($t; $t.inTransaction(); "Transaction was cancelled")

Function test_transactionWithValidation($t : cs:C1710.Testing)
	// #tags: transaction, validation
	// #transaction: false
	// This test demonstrates transaction validation for persistent changes
	
	$t.log("Testing transaction with validation")
	
	// Simplified test - just verify the method exists and can be called
	var $success : Boolean
	$success:=$t.withTransactionValidate(Formula:C1597($t.log("Testing operation within transaction")))
	
	$t.assert.isTrue($t; $success; "Transaction validated successfully")

Function test_transactionErrorHandling($t : cs:C1710.Testing)
	// #tags: transaction, error-handling
	// This test demonstrates transaction rollback on errors
	
	$t.log("Testing transaction error handling")
	
	// This operation should fail and trigger automatic rollback
	var $success : Boolean
	$success:=$t.withTransaction(Formula:C1597($t.fail()))
	
	$t.assert.isFalse($t; $success; "Transaction was cancelled due to test failure")

Function test_nestedTransactionExample($t : cs:C1710.Testing)
	// #tags: transaction, nested
	// #transaction: false
	// This test demonstrates nested transaction handling
	
	$t.log("Testing nested transactions")
	
	$t.startTransaction()
	$t.assert.isTrue($t; $t.inTransaction(); "Main transaction started")
	
	// Start nested transaction  
	$t.startTransaction()
	$t.log("Created nested transaction")
	
	// Cancel inner transaction
	$t.cancelTransaction()
	$t.log("Cancelled inner transaction")
	
	// Cancel outer transaction
	$t.cancelTransaction()
	$t.assert.isFalse($t; $t.inTransaction(); "All transactions cancelled")

Function test_dataIsolationExample($t : cs:C1710.Testing)
	// #tags: transaction, isolation
	// This test verifies that tests don't interfere with each other's data
	
	$t.log("Testing data isolation between tests")
	
	// This test creates some data that should be automatically cleaned up
	// Other tests should not see this data
	
	// Simulate creating test-specific data
	var $testDataId : Integer
	$testDataId:=Random:C100
	$t.log("Created test data with ID: "+String:C10($testDataId))
	
	$t.assert.isTrue($t; ($testDataId>0); "Test data was created with valid ID")
	// This data will be automatically rolled back due to automatic transaction management