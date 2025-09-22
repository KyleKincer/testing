//%attributes = {}
#DECLARE($processNumber : Integer; $options : Object)

var $hasOptions : Boolean
$hasOptions:=(Count parameters:C259>=2) && ($options#Null:C1517)

var $previousLocalHandler : Text
var $previousGlobalHandler : Text
var $shouldForwardLocal : Boolean
var $shouldForwardGlobal : Boolean

If ($hasOptions)
        $previousLocalHandler:=$options.previousLocalHandler || ""
        $previousGlobalHandler:=$options.previousGlobalHandler || ""
        $shouldForwardLocal:=Bool:C1537($options.forwardLocal)
        $shouldForwardGlobal:=Bool:C1537($options.forwardGlobal)
Else
        $previousLocalHandler:=""
        $previousGlobalHandler:=""
        $shouldForwardLocal:=False:C215
        $shouldForwardGlobal:=False:C215
End if

Use (Storage:C1525)
        If (Storage:C1525.testErrorHandlerProcesses=Null:C1517)
                Storage:C1525.testErrorHandlerProcesses:=New shared collection:C1527
        End if

        If (Storage:C1525.testErrorHandlerForwarding=Null:C1517)
                Storage:C1525.testErrorHandlerForwarding:=New shared object:C1526(\
                        "local"; New shared object:C1526; \
                        "global"; New shared object:C1526(\
                                "handler"; ""; \
                                "shouldForward"; False:C215; \
                                "installedProcess"; 0\
                        )\
                )
        End if
End use

Use (Storage:C1525.testErrorHandlerProcesses)
        If (Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)<0)
                Storage:C1525.testErrorHandlerProcesses.push($processNumber)
        End if
End use

var $forwardingState : Object
Use (Storage:C1525)
        $forwardingState:=Storage:C1525.testErrorHandlerForwarding
End use

If ($forwardingState#Null:C1517)
        var $key : Text
        $key:=String:C10($processNumber)

        var $localMap : Object
        Use ($forwardingState)
                If ($forwardingState.local=Null:C1517)
                        $forwardingState.local:=New shared object:C1526
                End if
                $localMap:=$forwardingState.local
        End use

        var $localEntry : Object
        Use ($localMap)
                $localEntry:=$localMap[$key]
                If ($localEntry=Null:C1517)
                        $localEntry:=New shared object:C1526(\
                                "handler"; ""; \
                                "shouldForward"; False:C215\
                        )
                        $localMap[$key]:=$localEntry
                End if
        End use

        Use ($localEntry)
                $localEntry.handler:=$previousLocalHandler
                $localEntry.shouldForward:=$shouldForwardLocal
        End use

        var $globalState : Object
        Use ($forwardingState)
                $globalState:=$forwardingState.global
        End use

        If ($globalState=Null:C1517)
                $globalState:=New shared object:C1526(\
                        "handler"; ""; \
                        "shouldForward"; False:C215; \
                        "installedProcess"; 0\
                )
                Use ($forwardingState)
                        $forwardingState.global:=$globalState
                End use
        End if

        Use ($globalState)
                If ($hasOptions)
                        $globalState.handler:=$previousGlobalHandler
                        $globalState.shouldForward:=$shouldForwardGlobal
                        If ($shouldForwardGlobal)
                                $globalState.installedProcess:=$processNumber
                        Else
                                $globalState.installedProcess:=($globalState.installedProcess#Null:C1517) ? $globalState.installedProcess : 0
                        End if
                End if
        End use
End if
