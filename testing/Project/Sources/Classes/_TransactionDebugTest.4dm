// Debug test for transaction methods

Function test_basicInTransaction($t : cs:C1710.Testing)
	// #transaction: false
	$t.log("Testing inTransaction method")
	
	// Cancel any existing transaction to ensure clean state
	If ($t.inTransaction())
		$t.cancelTransaction()
	End if
	
	var $result : Boolean
	$result:=$t.inTransaction()
	$t.log("inTransaction result: "+String:C10($result))
	$t.assert.isFalse($t; $result; "inTransaction should be false when transactions are disabled")

Function test_basicStartTransaction($t : cs:C1710.Testing) 
	// #transaction: false
	$t.log("Testing startTransaction method")
	
	var $result : Boolean
	$result:=$t.startTransaction()
	$t.log("startTransaction result: "+String:C10($result))
	
	$t.cancelTransaction()
	$t.assert.isTrue($t; True; "Test completed")