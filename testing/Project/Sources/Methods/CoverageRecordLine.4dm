//%attributes = {"shared":true}
// Records line execution for code coverage tracking
// This method wraps Storage access with proper Use...End use
#DECLARE($methodName : Text; $lineNumber : Integer)

If (Storage:C1525.coverage=Null:C1517) || (Storage:C1525.coverage.data=Null:C1517)
	return 
End if 

Use (Storage:C1525.coverage.data)
	If (Storage:C1525.coverage.data[$methodName]=Null:C1517)
		Storage:C1525.coverage.data[$methodName]:=New shared object:C1526
	End if 
	
	Use (Storage:C1525.coverage.data[$methodName])
		var $lineKey : Text
		var $currentCount : Integer
		$lineKey:=String:C10($lineNumber)
		$currentCount:=Num:C11(Storage:C1525.coverage.data[$methodName][$lineKey])
		Storage:C1525.coverage.data[$methodName][$lineKey]:=$currentCount+1
	End use 
End use 
