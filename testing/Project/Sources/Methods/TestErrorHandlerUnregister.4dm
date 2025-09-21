//%attributes = {}
#DECLARE($processNumber : Integer)

If (Storage:C1525.testErrorHandlerProcesses#Null:C1517)
        Use (Storage:C1525.testErrorHandlerProcesses)
                var $index : Integer
                For ($index; Storage:C1525.testErrorHandlerProcesses.length-1; 0; -1)
                        If (Storage:C1525.testErrorHandlerProcesses[$index]=$processNumber)
                                Storage:C1525.testErrorHandlerProcesses.remove($index)
                        End if
                End for
        End use
End if

If (Storage:C1525.testErrorHandlerState#Null:C1517)
        var $processKey : Text
        $processKey:=String:C10($processNumber)

        If (Storage:C1525.testErrorHandlerState.localHandlers#Null:C1517)
                Use (Storage:C1525.testErrorHandlerState.localHandlers)
                        Storage:C1525.testErrorHandlerState.localHandlers[$processKey]:=Null:C1517
                End use
        End if

        If (Storage:C1525.testErrorHandlerState.localHandlerChanges#Null:C1517)
                Use (Storage:C1525.testErrorHandlerState.localHandlerChanges)
                        Storage:C1525.testErrorHandlerState.localHandlerChanges[$processKey]:=False:C215
                End use
        End if
End if
