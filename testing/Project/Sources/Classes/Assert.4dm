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

Function throwsError($t : Object; $method : 4D:C1709.Function; $expectedCode : Integer; $message : Text)
        // Verify that executing the method results in a runtime error

        // Ensure error storage exists
        If (Storage:C1525.testErrors=Null:C1517)
                Use (Storage:C1525)
                        Storage:C1525.testErrors:=New shared collection:C1527
                End use
        End if

        var $beforeCount : Integer
        $beforeCount:=Storage:C1525.testErrors.length

        // Execute the provided method
        $method.apply()

        var $afterCount : Integer
        $afterCount:=Storage:C1525.testErrors.length

        // If no new error was recorded, the assertion fails
        If ($afterCount<=$beforeCount)
                If (Count parameters>=4)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Expected error but none was thrown")
                End if
                return
        End if

        // Capture the last error for verification
        var $lastError : Object
        $lastError:=Storage:C1525.testErrors[$afterCount-1]

        // Clear captured errors to avoid affecting outer test context
        Use (Storage:C1525)
                Storage:C1525.testErrors.clear()
        End use

        // If an expected error code was provided, verify it
        If (Count parameters>=3) && ($expectedCode#0)
                If ($lastError.code#$expectedCode)
                        var $defaultMessage : Text
                        $defaultMessage:="Expected error code "+String:C10($expectedCode)+" but got "+String:C10($lastError.code)
                        If (Count parameters>=4)
                                This.fail($t; $message+": "+$defaultMessage)
                        Else
                                This.fail($t; $defaultMessage)
                        End if
                End if
        End if


