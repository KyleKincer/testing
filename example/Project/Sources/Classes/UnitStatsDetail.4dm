/* Class: UnitStatsDetail
Keeps track of parameters that an instance of this class consumes.
*/

property _parametersCalledWith : Collection  // Type: Collection of Collections - [[...], [...], ...]

Class constructor
	This:C1470.reset()
	
Function reset()
/* Resets all properties on this class to default
*/
	This:C1470._parametersCalledWith:=[]
	
Function appendCalledParameters($parameters : Collection)
/* Appends parameters to details
	
$parameters - Collection - collection to append to the called with details
*/
	This:C1470._parametersCalledWith.push((($parameters#Null:C1517) ? $parameters : []))
	
Function getNumberOfCalls() : Integer
/* Returns the amount of times called based on the length of the internal collection
Calling `appendCalledParameters()` will increase this number.
Calling `reset()` will reset this value back down to 0.
	
returns - Integer - amount of calls on this structure
*/
	return This:C1470._parametersCalledWith.length
	
Function getXCallYParameter($xCall : Integer; $yParam : Integer) : Variant
/* Gets the X call and Y parameter from the saved parameter detail collection
	
$xCall - Integer - the N-th call to lookup (Starting at 1)
$yParam - Integer - the N-th parameter to lookup respective to the X call (Starting at 1)
*/
	var $callIndex; $paramIndex : Integer
	$callIndex:=$xCall-1
	$paramIndex:=$yParam-1
	Case of 
		: ($callIndex<0) || ($paramIndex<0)
			// handle invalid cases - 0 or negative $xCall; negative $yParam 
			// handle Nth call with no parameter function
			return Null:C1517
		: (Value type:C1509(This:C1470._parametersCalledWith)#Is collection:K8:32)
			return Null:C1517
		: ($callIndex>(This:C1470._parametersCalledWith.length-1))  // Call does not exist
			return Null:C1517
		: (Value type:C1509(This:C1470._parametersCalledWith[$callIndex])#Is collection:K8:32)
			return Null:C1517
		: ($paramIndex>(This:C1470._parametersCalledWith[$callIndex].length-1))  // Not enough parameters in call
			return Null:C1517
	End case 
	return This:C1470._parametersCalledWith[$callIndex][$paramIndex]
	
Function getXCallParams($xCall : Integer) : Collection
/* Gets the collection from the N-th call
$xCall - Integer - the N-th call to lookup (starting at 1)
returns - Collection - the collection for the N-th call to get
*/
	var $callIndex : Integer
	$callIndex:=$xCall-1
	Case of 
		: ($callIndex<0)
			return Null:C1517
		: (Value type:C1509(This:C1470._parametersCalledWith)#Is collection:K8:32)
			return Null:C1517
		: ($callIndex>(This:C1470._parametersCalledWith.length-1))  // Call does not exist
			return Null:C1517
		: (Value type:C1509(This:C1470._parametersCalledWith[$callIndex])#Is collection:K8:32)
			return Null:C1517
	End case 
	return This:C1470._parametersCalledWith[$callIndex]
	
Function getXCallParamLength($xCall : Integer) : Integer
/* Gets the length of the parameter collection that was used for the Nth call
$xCall - Integer - the N-th call to lookup (Starting at 1)
returns - Integer - the length of the collection used for the N-th call (0 if the call was not made yet)
*/
	var $collection : Collection
	$collection:=This:C1470.getXCallParams($xCall)
	return ($collection#Null:C1517) ? $collection.length : 0
	