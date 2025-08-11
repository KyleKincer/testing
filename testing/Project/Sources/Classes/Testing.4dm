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
	