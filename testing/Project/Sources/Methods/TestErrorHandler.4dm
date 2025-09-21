//%attributes = {}
// TestErrorHandler
// Global error handler for the testing framework
// Captures runtime errors to prevent test interruption

var $errorCode : Integer
var $errorText : Text
var $errorMethod : Text
var $errorLine : Integer
var $processNumber : Integer
var $isLocalProcess : Boolean
var $context : Text
var $previousLocalHandler : Text
var $previousGlobalHandler : Text
var $shouldCallPreviousLocal : Boolean
var $shouldCallPreviousGlobal : Boolean
var $processKey : Text

$errorCode:=Error
$errorText:=Error method
$errorMethod:=Error formula
$errorLine:=Error line
$processNumber:=Current process:C322
$isLocalProcess:=False:C215
$previousLocalHandler:=""
$previousGlobalHandler:=""
$shouldCallPreviousLocal:=False:C215
$shouldCallPreviousGlobal:=False:C215
$processKey:=String:C10($processNumber)

If (Storage:C1525.testErrorHandlerProcesses#Null:C1517)
        Use (Storage:C1525.testErrorHandlerProcesses)
                $isLocalProcess:=(Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)>=0)
        End use
End if

$context:=Choose:C955($isLocalProcess; "local"; "global")

If (Storage:C1525.testErrorHandlerState#Null:C1517)
        Use (Storage:C1525.testErrorHandlerState)
                If ($isLocalProcess)
                        var $localHandlers : Object
                        var $localChanges : Object
                        $localHandlers:=Storage:C1525.testErrorHandlerState.localHandlers
                        $localChanges:=Storage:C1525.testErrorHandlerState.localHandlerChanges

                        If ($localChanges#Null:C1517)
                                If ($localChanges[$processKey]#Null:C1517)
                                        $shouldCallPreviousLocal:=Bool:C1537($localChanges[$processKey])
                                End if
                        End if

                        If ($shouldCallPreviousLocal) && ($localHandlers#Null:C1517)
                                If ($localHandlers[$processKey]#Null:C1517)
                                        $previousLocalHandler:=String:C10($localHandlers[$processKey])
                                Else
                                        $shouldCallPreviousLocal:=False:C215
                                End if
                        End if
                Else
                        $shouldCallPreviousGlobal:=Bool:C1537(Storage:C1525.testErrorHandlerState.globalHandlerChanged)
                        If ($shouldCallPreviousGlobal)
                                $previousGlobalHandler:=Storage:C1525.testErrorHandlerState.previousGlobalHandler || ""
                        End if
                End if
        End use
End if

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

If ($shouldCallPreviousLocal)
        If ($previousLocalHandler#"") && ($previousLocalHandler#"TestErrorHandler")
                If (Method exists($previousLocalHandler))
                        EXECUTE METHOD($previousLocalHandler)
                Else
                        If (Method exists($previousLocalHandler; *))
                                EXECUTE METHOD($previousLocalHandler; *)
                        End if
                End if
        End if
End if

If ($shouldCallPreviousGlobal)
        If ($previousGlobalHandler#"") && ($previousGlobalHandler#"TestErrorHandler")
                If (Method exists($previousGlobalHandler))
                        EXECUTE METHOD($previousGlobalHandler)
                Else
                        If (Method exists($previousGlobalHandler; *))
                                EXECUTE METHOD($previousGlobalHandler; *)
                        End if
                End if
        End if
End if

// Continue execution - don't interrupt the test
