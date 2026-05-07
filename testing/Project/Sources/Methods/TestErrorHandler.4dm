//%attributes = {}
// TestErrorHandler
// Local error handler for the testing framework
// Captures runtime errors and records minimal metadata for later reporting

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
$context:="local"
$isLocalProcess:=True:C214

// Get human-readable error description from Last errors
var $errorMessage : Text
$errorMessage:=""
var $lastErrors : Collection
$lastErrors:=Last errors
If ($lastErrors#Null:C1517) && ($lastErrors.length>0)
        $errorMessage:=$lastErrors[0].message
End if

// Store error information in Storage for later retrieval
If (Storage:C1525.testErrors=Null:C1517)
        Use (Storage:C1525)
                Storage:C1525.testErrors:=New shared collection:C1527
        End use
End if

var $rawChain : Collection
$rawChain:=Get call chain:C1662
// Strip the error handler and all framework internals from the chain
var $filteredChain : Collection
$filteredChain:=New collection:C1472
var $entry : Object
For each ($entry; $rawChain)
	// Drop the handler frame only — do not strip all "testing" DB frames, or real
	// test methods in the component disappear from the chain (review: PR #30).
	If ($entry.name#"TestErrorHandler")
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

// Continue execution - don't interrupt the test
