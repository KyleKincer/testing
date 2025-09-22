//%attributes = {}
#DECLARE($processNumber : Integer; $options : Object)

var $clearLocal : Boolean
var $clearGlobal : Boolean

$clearLocal:=True:C214
$clearGlobal:=False:C215

If (Count parameters:C259>=2) && ($options#Null:C1517)
        If ($options.clearLocal#Null:C1517)
                $clearLocal:=Bool:C1537($options.clearLocal)
        End if

        If ($options.clearGlobal#Null:C1517)
                $clearGlobal:=Bool:C1537($options.clearGlobal)
        End if
End if

If ($clearLocal)
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
End if

var $forwardingState : Object
Use (Storage:C1525)
        $forwardingState:=Storage:C1525.testErrorHandlerForwarding
End use

If ($forwardingState#Null:C1517)
        var $key : Text
        $key:=String:C10($processNumber)

        If ($clearLocal)
                var $localMap : Object
                Use ($forwardingState)
                        $localMap:=$forwardingState.local
                End use

                If ($localMap#Null:C1517)
                        var $localEntry : Object
                        Use ($localMap)
                                $localEntry:=$localMap[$key]
                        End use

                        If ($localEntry#Null:C1517)
                                Use ($localEntry)
                                        $localEntry.handler:=""
                                        $localEntry.shouldForward:=False:C215
                                End use
                        End if
                End if
        End if

        If ($clearGlobal)
                var $globalState : Object
                Use ($forwardingState)
                        $globalState:=$forwardingState.global
                End use

                If ($globalState#Null:C1517)
                        Use ($globalState)
                                $globalState.shouldForward:=False:C215
                                $globalState.installedProcess:=0
                        End use
                End if
        End if
End if
