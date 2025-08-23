//%attributes = {}
// TestErrorHandler
// Global error handler for the testing framework
// Captures runtime errors to prevent test interruption

var $errorCode : Integer
var $errorText : Text
var $errorMethod : Text
var $errorLine : Integer

$errorCode:=Error
$errorText:=Error method
$errorMethod:=Error formula
$errorLine:=Error line

// Determine current process for thread-safe storage
var $processId : Text
$processId:=String:C10(Current process:C322)

// Ensure per-process error collection exists
Use (Storage:C1525)
        If (Storage:C1525.testErrorsByProcess=Null:C1517)
                Storage:C1525.testErrorsByProcess:=New shared object:C1526
        End if
End use

Use (Storage:C1525.testErrorsByProcess)
        If (Storage:C1525.testErrorsByProcess[$processId]=Null:C1517)
                Storage:C1525.testErrorsByProcess[$processId]:=New shared collection:C1527
        End if
End use

var $errorInfo : Object
$errorInfo:=New object:C1471(\
"code"; $errorCode; \
"text"; $errorText; \
"method"; $errorMethod; \
"line"; $errorLine; \
"timestamp"; Milliseconds:C459\
)

var $errorCollection : Collection
Use (Storage:C1525.testErrorsByProcess)
        $errorCollection:=Storage:C1525.testErrorsByProcess[$processId]
End use

Use ($errorCollection)
        $errorCollection.push(OB Copy($errorInfo; ck shared))
End use

// Continue execution - don't interrupt the test
