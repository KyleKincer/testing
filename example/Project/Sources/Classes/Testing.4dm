// Acts as the test context

property failed : Boolean
property done : Boolean
property logMessages : Collection

Class constructor()
	This:C1470.failed:=False:C215
	This:C1470.done:=False:C215
	This:C1470.logMessages:=[]
	
Function log($message : Text)
	This:C1470.logMessages.push($message)
	
Function fail()
	This:C1470.failed:=True:C214
	
Function fatal()
	This:C1470.failed:=True:C214
	This:C1470.done:=True:C214
	
Function run($name : Text; $subtest : 4D:C1709.Function)
	// This will be implemented later
	