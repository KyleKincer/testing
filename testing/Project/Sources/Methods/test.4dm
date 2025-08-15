//%attributes = {}
// Parse user parameters to check for parallel execution
var $userParam : Text
var $real : Real
$real:=Get database parameter:C643(User param value:K37:94; $userParam)

var $params : Object
$params:=New object:C1471
// Parse space-separated key=value pairs
var $parts : Collection
$parts:=Split string:C1554($userParam; " ")

var $part : Text
For each ($part; $parts)
	$part:=Replace string:C233($part; " "; "")  // Remove any extra spaces
	If ($part#"")
		var $keyValue : Collection
		
		// Try = separator first
		If (Position:C15("="; $part)>0)
			$keyValue:=Split string:C1554($part; "=")
			If ($keyValue.length=2)
				$params[$keyValue[0]]:=$keyValue[1]
			End if 
		End if 
	End if 
End for each

// Determine which runner to use
var $runner : Object
If ($params.parallel="true")
	$runner:=cs:C1710.ParallelTestRunner.new()
Else
	$runner:=cs:C1710.TestRunner.new()
End if

If (Application info:C1599.headless)
	$runner.run()
	
	If (Application type:C494#6)
		QUIT 4D:C291
	End if 
	
Else 
	$runner.run()
End if 