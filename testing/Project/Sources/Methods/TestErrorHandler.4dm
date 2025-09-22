//%attributes = {}
// TestErrorHandler
// Global error handler for the testing framework
// Captures runtime errors, stores metadata, and forwards to previous handlers when necessary

var $errorCode : Integer
var $errorText : Text
var $errorMethod : Text
var $errorLine : Integer
var $processNumber : Integer
var $isLocalProcess : Boolean
var $context : Text
var $previousHandler : Text
var $shouldForward : Boolean

$errorCode:=Error
$errorText:=Error method
$errorMethod:=Error formula
$errorLine:=Error line
$processNumber:=Current process:C322
$isLocalProcess:=False:C215
$previousHandler:=""
$shouldForward:=False:C215

If (Storage:C1525.testErrorHandlerProcesses#Null:C1517)
        Use (Storage:C1525.testErrorHandlerProcesses)
                $isLocalProcess:=(Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)>=0)
        End use
End if

var $forwardingState : Object
Use (Storage:C1525)
        $forwardingState:=Storage:C1525.testErrorHandlerForwarding
End use

If ($forwardingState#Null:C1517)
        If ($isLocalProcess)
                var $localMap : Object
                Use ($forwardingState)
                        $localMap:=$forwardingState.local
                End use

                If ($localMap#Null:C1517)
                        var $localEntry : Object
                        Use ($localMap)
                                $localEntry:=$localMap[String:C10($processNumber)]
                        End use

                        If ($localEntry#Null:C1517)
                                Use ($localEntry)
                                        $previousHandler:=$localEntry.handler || ""
                                        $shouldForward:=Bool:C1537($localEntry.shouldForward)
                                End use
                        End if
                End if
        Else
                var $globalState : Object
                Use ($forwardingState)
                        $globalState:=$forwardingState.global
                End use

                If ($globalState#Null:C1517)
                        Use ($globalState)
                                $previousHandler:=$globalState.handler || ""
                                $shouldForward:=Bool:C1537($globalState.shouldForward)
                        End use
                End if
        End if
End if

$context:=Choose:C955($isLocalProcess; "local"; "global")

// Store error information in Storage for later retrieval
If (Storage:C1525.testErrors=Null:C1517)
        Use (Storage:C1525)
                Storage:C1525.testErrors:=New shared collection:C1527
        End use
End if

var $errorInfo : Object
$errorInfo:=New object:C1471(\
"code"; $errorCode; \
"text"; $errorText; \
"method"; $errorMethod; \
"line"; $errorLine; \
"timestamp"; Milliseconds:C459; \
"processNumber"; $processNumber; \
"context"; $context; \
"isLocal"; $isLocalProcess\
)

Use (Storage:C1525.testErrors)
        Storage:C1525.testErrors.push(OB Copy:C1225($errorInfo; ck shared:K85:29))
End use

If ($shouldForward) && ($previousHandler#"") && ($previousHandler#"TestErrorHandler")
        EXECUTE METHOD:C1007($previousHandler)
End if

// Continue execution - don't interrupt the test
