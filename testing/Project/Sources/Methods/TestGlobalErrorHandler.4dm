//%attributes = {}
// TestGlobalErrorHandler
// Global error handler for the testing framework
// Captures runtime errors from processes without the local test handler

var $errorCode : Integer
var $errorText : Text
var $errorMethod : Text
var $errorLine : Integer
var $processNumber : Integer
var $context : Text
var $isLocalProcess : Boolean

$errorCode:=Error
$errorText:=Error method
$errorMethod:=Error formula
$errorLine:=Error line
$processNumber:=Current process:C322
$context:="global"
$isLocalProcess:=False:C215

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

// Allow execution to continue so the runner can report the failure
