// Debug test for transaction methods

Function test_basicInTransaction($t : cs:C1710.Testing)
	// #transaction: false
	$t.log("Testing inTransaction method")
	
	var $result : Boolean
	$result:=$t.inTransaction()
	$t.log("inTransaction result: "+String:C10($result))
	$t.assert.isTrue($t; True; "Test completed")

Function test_basicStartTransaction($t : cs:C1710.Testing) 
	// #transaction: false
	$t.log("Testing startTransaction method")
	
	var $result : Boolean
	$result:=$t.startTransaction()
	$t.log("startTransaction result: "+String:C10($result))
	
	$t.cancelTransaction()
	$t.assert.isTrue($t; True; "Test completed")