property class : 4D:C1709.Class
property classInstance : 4D:C1709.Object
property function : 4D:C1709.Function
property functionName : Text
property t : cs:C1710.Testing
property startTime : Integer
property endTime : Integer
property runtimeErrors : Collection

Class constructor($class : 4D:C1709.Class; $classInstance : 4D:C1709.Object; $function : 4D:C1709.Function; $name : Text)
	This:C1470.class:=$class
	This:C1470.classInstance:=$classInstance
	This:C1470.function:=$function
	This:C1470.functionName:=$name
	This:C1470.t:=cs:C1710.Testing.new()
	This:C1470.runtimeErrors:=[]
	
Function run()
	This:C1470.startTime:=Milliseconds:C459
	
	// Clear any existing test errors
	If (Storage:C1525.testErrors#Null:C1517)
		Use (Storage:C1525)
			Storage:C1525.testErrors.clear()
		End use 
	End if 
	
	// Set up error handler to capture runtime errors
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	This:C1470.function.apply(This:C1470.classInstance; [This:C1470.t])
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
	// Capture any runtime errors that occurred
	If (Storage:C1525.testErrors#Null:C1517) && (Storage:C1525.testErrors.length>0)
		var $error : Object
		For each ($error; Storage:C1525.testErrors)
			This:C1470.runtimeErrors.push(OB Copy:C1225($error))
		End for each 
		
		// Mark test as failed if runtime errors occurred
		This:C1470.t.fail()
	End if 
	
	This:C1470.endTime:=Milliseconds:C459
	
Function getResult() : Object
	var $duration : Integer
	$duration:=This:C1470.endTime-This:C1470.startTime
	
	return New object:C1471(\
		"name"; This:C1470.functionName; \
		"passed"; Not:C34(This:C1470.t.failed); \
		"failed"; This:C1470.t.failed; \
		"duration"; $duration; \
		"suite"; This:C1470.class.name; \
		"runtimeErrors"; This:C1470.runtimeErrors; \
		"logMessages"; This:C1470.t.logMessages\
		)