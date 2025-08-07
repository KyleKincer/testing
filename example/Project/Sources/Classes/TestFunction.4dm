property class : 4D:C1709.Class
property classInstance : 4D:C1709.Object
property function : 4D:C1709.Function
property functionName : Text
property t : cs:C1710.Testing
property startTime : Integer
property endTime : Integer

Class constructor($class : 4D:C1709.Class; $classInstance : 4D:C1709.Object; $function : 4D:C1709.Function; $name : Text)
	This:C1470.class:=$class
	This:C1470.classInstance:=$classInstance
	This:C1470.function:=$function
	This:C1470.functionName:=$name
	This:C1470.t:=cs:C1710.Testing.new()
	
Function run()
	This:C1470.startTime:=Milliseconds:C459
	This:C1470.function.apply(This:C1470.classInstance; [This:C1470.t])
	This:C1470.endTime:=Milliseconds:C459
	
Function getResult() : Object
	var $duration : Integer
	$duration:=This:C1470.endTime-This:C1470.startTime
	
	return New object:C1471(\
		"name"; This:C1470.functionName; \
		"passed"; Not:C34(This:C1470.t.failed); \
		"failed"; This:C1470.t.failed; \
		"duration"; $duration; \
		"suite"; This:C1470.class.name\
		)