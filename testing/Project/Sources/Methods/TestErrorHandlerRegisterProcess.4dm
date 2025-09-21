//%attributes = {}
#DECLARE($processNumber : Integer)

var $previousHandler : Text
var $handlerChanged : Boolean

$previousHandler:=""
$handlerChanged:=False:C215

If (Count parameters:C259>=2)
        $previousHandler:=$2
End if

If (Count parameters:C259>=3)
        $handlerChanged:=Bool:C1537($3)
End if

Use (Storage:C1525)
        If (Storage:C1525.testErrorHandlerProcesses=Null:C1517)
                Storage:C1525.testErrorHandlerProcesses:=New shared collection:C1527
        End if
End use

Use (Storage:C1525.testErrorHandlerProcesses)
        If (Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)<0)
                Storage:C1525.testErrorHandlerProcesses.push($processNumber)
        End if
End use

If (Storage:C1525.testErrorHandlerState#Null:C1517)
        var $processKey : Text
        $processKey:=String:C10($processNumber)

        If (Storage:C1525.testErrorHandlerState.localHandlers=Null:C1517)
                Use (Storage:C1525.testErrorHandlerState)
                        Storage:C1525.testErrorHandlerState.localHandlers:=New shared object:C1526()
                End use
        End if

        If (Storage:C1525.testErrorHandlerState.localHandlerChanges=Null:C1517)
                Use (Storage:C1525.testErrorHandlerState)
                        Storage:C1525.testErrorHandlerState.localHandlerChanges:=New shared object:C1526()
                End use
        End if

        If (Storage:C1525.testErrorHandlerState.localHandlers#Null:C1517)
                Use (Storage:C1525.testErrorHandlerState.localHandlers)
                        Storage:C1525.testErrorHandlerState.localHandlers[$processKey]:=$previousHandler
                End use
        End if

        If (Storage:C1525.testErrorHandlerState.localHandlerChanges#Null:C1517)
                Use (Storage:C1525.testErrorHandlerState.localHandlerChanges)
                        Storage:C1525.testErrorHandlerState.localHandlerChanges[$processKey]:=$handlerChanged
                End use
        End if
End if
