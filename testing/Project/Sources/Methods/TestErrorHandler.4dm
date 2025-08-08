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
"timestamp"; Milliseconds:C459\
)

Use (Storage:C1525.testErrors)
	Storage:C1525.testErrors.push(OB Copy($errorInfo; ck shared))
End use 

// Continue execution - don't interrupt the test