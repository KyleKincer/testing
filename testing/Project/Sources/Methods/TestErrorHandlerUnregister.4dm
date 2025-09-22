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

