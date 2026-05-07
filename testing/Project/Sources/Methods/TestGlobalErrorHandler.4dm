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

// Get human-readable error description from Last errors
var $errorMessage : Text
$errorMessage:=""
var $lastErrors : Collection
$lastErrors:=Last errors
If ($lastErrors#Null:C1517) && ($lastErrors.length>0)
        $errorMessage:=$lastErrors[0].message
End if

If (Storage:C1525.testErrors=Null:C1517)
        Use (Storage:C1525)
                Storage:C1525.testErrors:=New shared collection:C1527
        End use
End if

var $rawChain : Collection
$rawChain:=Get call chain:C1662
var $filteredChain : Collection
$filteredChain:=New collection:C1472
var $entry : Object
For each ($entry; $rawChain)
	If ($entry.name#"TestGlobalErrorHandler")
		$filteredChain.push($entry)
	End if
End for each
var $callChainJSON : Text
$callChainJSON:=JSON Stringify:C1217($filteredChain)

var $errorInfo : Object
$errorInfo:=New object:C1471(\
"code"; $errorCode; \
"text"; $errorText; \
"method"; $errorMethod; \
"line"; $errorLine; \
"message"; $errorMessage; \
"timestamp"; Milliseconds:C459; \
"processNumber"; $processNumber; \
"context"; $context; \
"isLocal"; $isLocalProcess; \
"callChainJSON"; $callChainJSON\
)

Use (Storage:C1525.testErrors)
        Storage:C1525.testErrors.push(OB Copy:C1225($errorInfo; ck shared:K85:29))
End use

// Allow execution to continue so the runner can report the failure
