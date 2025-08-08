/* Class: UnitStatsTracker
Provides tracking for mocked function when unit testing.
*/
property _statsMap : Object

Class constructor()
	This:C1470._statsMap:=New object:C1471
	
	// Mark:- Public Functions
	
Function resetStatistics()
/* Resets all of the statistics to their default states
*/
	If (This:C1470._statsMap=Null:C1517)
		return 
	End if 
	var $statistic : cs:C1710.UnitStatsDetail
	For each ($statistic; OB Values:C1718(This:C1470._statsMap))
		If (OB Instance of:C1731($statistic.reset; 4D:C1709.Function))
			$statistic.reset()
		End if 
	End for each 
	
Function createStatistic($name : Text) : cs:C1710.UnitStatsTracker
/* Creates a statistic with the given name
$name - text - the name of the statistic to create
returns - cs.UnitStatsTracker - This object to chain call
*/
	This:C1470._statsMap[$name]:=cs:C1710.UnitStatsDetail.new()
	return This:C1470
	
Function getStat($name : Text) : cs:C1710.UnitStatsDetail
/* Gets a statistic. If one does not exist, a new statistic will
be created an returned.
$name - text - the name of the statistic to return
returns - cs.UnitStatsDetail - a statistic
*/
	If (Not:C34(This:C1470._doesStatisticExist($name)))
		This:C1470.createStatistic($name)
	End if 
	return This:C1470._statsMap[$name]
	
Function mock($functionName : Text; $parameters : Collection; $returnValue : Variant) : Variant
/* Sets up a mock response while also updating the statistic.
The related statistic is updated with the parameters called.
$functionName - text - the name of the statistic to update
$parameters - collection - the collection of parameters to push onto the related statistic
$returnValue - variant - value this method will return
*/
	var $statistic : cs:C1710.UnitStatsDetail
	$statistic:=This:C1470.getStat($functionName)
	If ($statistic#Null:C1517)
		$statistic.appendCalledParameters((($parameters#Null:C1517) ? $parameters : []))
	End if 
	return $returnValue
	
	// Mark:- Private Functions
	
Function _doesStatisticExist($functionName : Text) : Boolean
/* Checks to see if a statistic already exists
$name - text - name of the statistic to check if exists
returns - boolean - whether the name of a statistic exists or not
*/
	return (OB Keys:C1719(This:C1470._statsMap).indexOf($functionName)>=0)
	