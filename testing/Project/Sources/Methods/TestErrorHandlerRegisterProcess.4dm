//%attributes = {}
#DECLARE($processNumber : Integer)

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
