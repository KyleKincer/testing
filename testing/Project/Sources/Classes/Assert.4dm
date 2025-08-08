Class constructor()

Function fail($t : Object; $message : Text)
	// Mark the test as failed and optionally log a message
	$t.fail()
	If ($message#"")
		$t.log($message)
	End if 

Function areEqual($t : Object; $expected : Variant; $actual : Variant; $message : Text)
	// If values are not equal, fail and log message
	If ($expected#$actual)
		If (Count parameters>=4)  // message provided
			This.fail($t; $message)
		Else 
			This.fail($t; "Assertion failed: values are not equal")
		End if 
	End if 

Function isTrue($t : Object; $value : Variant; $message : Text)
	If (Not($value))
		If (Count parameters>=3)
			This.fail($t; $message)
		Else 
			This.fail($t; "Assertion failed: value is not true")
		End if 
	End if 

Function isFalse($t : Object; $value : Variant; $message : Text)
	If ($value)
		If (Count parameters>=3)
			This.fail($t; $message)
		Else 
			This.fail($t; "Assertion failed: value is not false")
		End if 
	End if 

Function isNull($t : Object; $value : Variant; $message : Text)
	If ($value#Null)
		If (Count parameters>=3)
			This.fail($t; $message)
		Else 
			This.fail($t; "Assertion failed: value is not Null")
		End if 
	End if 

Function isNotNull($t : Object; $value : Variant; $message : Text)
	If ($value=Null)
		If (Count parameters>=3)
			This.fail($t; $message)
		Else 
			This.fail($t; "Assertion failed: value is Null")
		End if 
	End if 


