// Acts as the test context

property failed : Boolean
property done : Boolean

Class constructor()
	This:C1470.failed:=False:C215
	This:C1470.done:=False:C215
	
Function log($message : Text)
	LOG EVENT:C667(Into system standard outputs:K38:9; $message; Error message:K38:3)
	
Function fail()
	This:C1470.failed:=True:C214
	
Function fatal()
	This:C1470.failed:=True:C214
	This:C1470.done:=True:C214
	
Function run($name : Text; $subtest : 4D:C1709.Function)
	// This will be implemented later
	