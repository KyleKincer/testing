// Acts as the test context

property failed : Boolean
property done : Boolean
property logMessages : Collection
property assert : cs:C1710.Assert
property stats : cs:C1710.UnitStatsTracker

Class constructor()
	This:C1470.failed:=False:C215
	This:C1470.done:=False:C215
	This:C1470.logMessages:=[]
	This:C1470.assert:=cs:C1710.Assert.new()
	This:C1470.stats:=cs:C1710.UnitStatsTracker.new()
	
Function log($message : Text)
	This:C1470.logMessages.push($message)
	
Function fail()
	This:C1470.failed:=True:C214
	
Function fatal()
	This:C1470.failed:=True:C214
	This:C1470.done:=True:C214
	
Function resetForNewTest()
	This:C1470.failed:=False:C215
	This:C1470.done:=False:C215
	This:C1470.logMessages:=[]
	This:C1470.stats.resetStatistics()
	
Function run($name : Text; $subtest : 4D:C1709.Function)
	// This will be implemented later

// Transaction management methods for manual control

Function startTransaction() : Boolean
	// Start a transaction and return success status
	START TRANSACTION:C239
	return True

Function validateTransaction() : Boolean
	// Validate the current transaction
	VALIDATE TRANSACTION:C240
	return (OK:C209=1)

Function cancelTransaction()
	// Cancel the current transaction
	CANCEL TRANSACTION:C241

Function inTransaction() : Boolean
	// Check if we're currently in a transaction
	return (In transaction:C397)

Function withTransaction($operation : 4D:C1709.Function) : Boolean
	// Execute an operation within a transaction
	// Returns true if operation succeeded and transaction was validated
	var $success : Boolean
	$success:=False
	
	START TRANSACTION:C239
	
	// Set up error handler to catch any errors during operation
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	$operation.apply()
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
	// Check if operation succeeded (no test failures)
	If (Not:C34(This:C1470.failed))
		CANCEL TRANSACTION:C241  // Always rollback for withTransaction
		$success:=True
	Else 
		CANCEL TRANSACTION:C241
		$success:=False
	End if 
	
	return $success

Function withTransactionValidate($operation : 4D:C1709.Function) : Boolean
	// Execute an operation within a transaction and always validate on success
	// Useful for tests that need to persist data
	var $success : Boolean
	$success:=False
	
	START TRANSACTION:C239
	
	// Set up error handler to catch any errors during operation
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	$operation.apply()
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
	// Validate transaction if test succeeded
	If (Not:C34(This:C1470.failed))
		VALIDATE TRANSACTION:C240
		$success:=(OK:C209=1)
	Else 
		CANCEL TRANSACTION:C241
		$success:=False
	End if 
	
	return $success
	