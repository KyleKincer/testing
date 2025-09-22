//%attributes = {}
// TestErrorHandler
// Global error handler for the testing framework
// Captures runtime errors and records minimal metadata for later reporting

var $errorCode : Integer
var $errorText : Text
var $errorMethod : Text
var $errorLine : Integer
var $processNumber : Integer
var $isLocalProcess : Boolean
var $context : Text

$errorCode:=Error
$errorText:=Error method
$errorMethod:=Error formula
$errorLine:=Error line
$processNumber:=Current process:C322
$isLocalProcess:=False:C215

If (Storage:C1525.testErrorHandlerProcesses#Null:C1517)
        Use (Storage:C1525.testErrorHandlerProcesses)
                If (Storage:C1525.testErrorHandlerProcesses.indexOf($processNumber)>=0)
                        $isLocalProcess:=True:C214
                        $context:="local"
                End if
        End use
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

// Continue execution - don't interrupt the test
