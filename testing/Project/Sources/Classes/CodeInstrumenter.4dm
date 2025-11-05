// Instruments code with coverage tracking calls
// Uses METHOD GET CODE and METHOD SET CODE to inject coverage tracking

property originalCode : Object  // Map of method path -> original code
property instrumentedMethods : Collection  // Collection of instrumented method paths
property coverageTracker : cs.CoverageTracker
property hostStorage : Object  // Host project's Storage for method access

Class constructor($hostStorage : Object)
	This.originalCode:=New object
	This.instrumentedMethods:=[]
	This.coverageTracker:=Null
	This.hostStorage:=$hostStorage
	
Function instrumentMethod($methodPath : Text) : Boolean
	// Instrument a single method with coverage tracking
	// Returns true if successful
	
	var $code : Text
	var $errorCode : Integer
	
	// Get original code
	METHOD GET CODE($methodPath; $code; *; $errorCode)
	
	If ($errorCode#0) || ($code="")
		return False
	End if 
	
	// Store original code for restoration
	This.originalCode[$methodPath]:=$code
	
	// Instrument the code
	var $instrumentedCode : Text
	$instrumentedCode:=This._instrumentCodeLines($code; $methodPath)
	
	// Set instrumented code
	METHOD SET CODE($methodPath; $instrumentedCode; *; $errorCode)
	
	If ($errorCode#0)
		return False
	End if 
	
	This.instrumentedMethods.push($methodPath)
	return True
	
Function instrumentMethods($methodPaths : Collection) : Object
	// Instrument multiple methods
	// Returns statistics about instrumentation
	
	var $stats : Object
	var $successCount; $failureCount : Integer
	var $failures : Collection
	
	$successCount:=0
	$failureCount:=0
	$failures:=[]
	
	var $methodPath : Text
	For each ($methodPath; $methodPaths)
		If (This.instrumentMethod($methodPath))
			$successCount:=$successCount+1
		Else 
			$failureCount:=$failureCount+1
			$failures.push($methodPath)
		End if 
	End for each 
	
	$stats:=New object(\
		"total"; $methodPaths.length; \
		"success"; $successCount; \
		"failed"; $failureCount; \
		"failures"; $failures\
		)
	
	return $stats
	
Function restoreOriginalCode() : Boolean
	// Restore all instrumented methods to their original code
	var $success : Boolean
	$success:=True
	
	var $methodPath : Text
	For each ($methodPath; This.instrumentedMethods)
		var $originalCode : Text
		$originalCode:=This.originalCode[$methodPath]
		
		var $errorCode : Integer
		METHOD SET CODE($methodPath; $originalCode; *; $errorCode)
		
		If ($errorCode#0)
			$success:=False
		End if 
	End for each 
	
	// Clear tracking
	This.originalCode:=New object
	This.instrumentedMethods:=[]
	
	return $success
	
Function _instrumentCodeLines($code : Text; $methodPath : Text) : Text
	// Instrument code by injecting coverage tracking calls
	// Strategy: Add tracking call at the start of each executable line
	
	var $lines : Collection
	$lines:=Split string($code; "\r"; sk ignore empty strings)
	
	var $instrumentedLines : Collection
	$instrumentedLines:=[]
	
	var $lineNumber : Integer
	var $line : Text
	var $inMultilineComment : Boolean
	$inMultilineComment:=False
	
	For ($lineNumber; 0; $lines.length-1)
		$line:=$lines[$lineNumber]
		
		// Track multiline comments (/* ... */)
		If (Position("/*"; $line)>0)
			$inMultilineComment:=True
		End if 
		
		If (This._isExecutableLine($line; $inMultilineComment))
			// Inject coverage tracking before executable line
			var $indent : Text
			$indent:=This._getLineIndentation($line)
			
			var $trackingCall : Text
			$trackingCall:=$indent+"CoverageRecordLine(\""+$methodPath+"\"; "+String($lineNumber+1)+")"
			
			$instrumentedLines.push($trackingCall)
		End if 
		
		// Add original line
		$instrumentedLines.push($line)
		
		// End multiline comment tracking
		If (Position("*/"; $line)>0)
			$inMultilineComment:=False
		End if 
	End for 
	
	return $instrumentedLines.join("\r")
	
Function _isExecutableLine($line : Text; $inMultilineComment : Boolean) : Boolean
	// Determine if a line should be instrumented
	var $trimmedLine : Text
	$trimmedLine:=This._trim($line)
	
	// Skip if in multiline comment
	If ($inMultilineComment)
		return False
	End if 
	
	// Skip empty lines
	If ($trimmedLine="")
		return False
	End if 
	
	// Skip single-line comments
	If (Position("//"; $trimmedLine)=1)
		return False
	End if 
	
	// Skip comment-only lines
	If (Position("/*"; $trimmedLine)=1) && (Position("*/"; $trimmedLine)>0)
		return False
	End if 
	
	// Skip class/function declarations
	If (Position("Class constructor"; $trimmedLine)=1)
		return False
	End if 
	
	If (Position("Function "; $trimmedLine)=1)
		return False
	End if 
	
	If (Position("property "; $trimmedLine)=1)
		return False
	End if 
	
	// Skip control structure keywords that don't execute code themselves
	Case of 
		: ($trimmedLine="End if")
			return False
		: ($trimmedLine="End case")
			return False
		: ($trimmedLine="End for")
			return False
		: ($trimmedLine="End for each")
			return False
		: ($trimmedLine="End while")
			return False
		: ($trimmedLine="End use")
			return False
		: ($trimmedLine="Else")
			return False
	End case 
	
	// If we got here, it's likely an executable line
	return True
	
Function _getLineIndentation($line : Text) : Text
	// Extract the leading whitespace from a line
	var $indent : Text
	var $i : Integer
	
	$indent:=""
	
	For ($i; 1; Length($line))
		var $char : Text
		$char:=Substring($line; $i; 1)
		
		If ($char=" ") || ($char=Char(Tab))
			$indent:=$indent+$char
		Else 
			return $indent
		End if 
	End for 
	
	return $indent
	
Function _trim($text : Text) : Text
	// Trim leading and trailing whitespace
	var $result : Text
	$result:=$text
	
	// Trim leading
	While (Length($result)>0) && ((Substring($result; 1; 1)=" ") || (Substring($result; 1; 1)=Char(Tab)))
		$result:=Substring($result; 2)
	End while 
	
	// Trim trailing
	While (Length($result)>0) && ((Substring($result; Length($result); 1)=" ") || (Substring($result; Length($result); 1)=Char(Tab)))
		$result:=Substring($result; 1; Length($result)-1)
	End while 
	
	return $result
	
Function getInstrumentedMethodPaths() : Collection
	// Return collection of instrumented method paths
	return This.instrumentedMethods.copy()
	
Function getOriginalCode($methodPath : Text) : Text
	// Get original code for a method
	return This.originalCode[$methodPath]
