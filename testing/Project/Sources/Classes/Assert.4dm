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

Function throws($t : Object; $operation : 4D:C1709.Function; $message : Text)
        // Assert that executing the operation results in a runtime error
        var $initialCount : Integer
        var $finalCount : Integer
        var $processId : Text
        var $errorCollection : Collection
        $processId:=String:C10(Current process:C322)
        Use (Storage:C1525)
                If (Storage:C1525.testErrorsByProcess=Null:C1517)
                        Storage:C1525.testErrorsByProcess:=New shared object:C1526
                End if
        End use

        Use (Storage:C1525.testErrorsByProcess)
                If (Storage:C1525.testErrorsByProcess[$processId]=Null:C1517)
                        Storage:C1525.testErrorsByProcess[$processId]:=New shared collection:C1527
                End if
                $errorCollection:=Storage:C1525.testErrorsByProcess[$processId]
                $initialCount:=$errorCollection.length
        End use

        var $previousHandler : Text
        $previousHandler:=Method called on error:C704
        ON ERR CALL:C155("TestErrorHandler")
        $operation.apply()
        If ($previousHandler#"")
                ON ERR CALL:C155($previousHandler)
        Else
                ON ERR CALL:C155("")
        End if

        Use (Storage:C1525.testErrorsByProcess)
                $errorCollection:=Storage:C1525.testErrorsByProcess[$processId]
        End use

        Use ($errorCollection)
                $finalCount:=$errorCollection.length
                If ($finalCount>$initialCount)
                        $errorCollection.pop()
                End if
        End use

        If ($finalCount<=$initialCount)
                If (Count parameters>=3)
                        This.fail($t; $message)
                Else
                        This.fail($t; "Assertion failed: operation did not throw an error")
                End if
        End if

