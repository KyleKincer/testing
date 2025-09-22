//%attributes = {}
#DECLARE($processNumber : Integer)

// Track processes that should be treated as local test contexts
If (Storage:C1525.testErrorHandlerProcesses=Null:C1517)
        Use (Storage:C1525)
                Storage:C1525.testErrorHandlerProcesses:=New shared collection:C1527
        End use
End if

Use (Storage:C1525.testErrorHandlerProcesses)
        If (Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)<0)
                Storage:C1525.testErrorHandlerProcesses.push($processNumber)
        End if
End use
