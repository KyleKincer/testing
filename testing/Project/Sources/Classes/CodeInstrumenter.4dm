// Instruments code by injecting coverage tracking calls
// Uses METHOD GET CODE and METHOD SET CODE

property originalCode : Object  // Map of methodPath -> original code
property instrumentedMethods : Collection  // List of instrumented method paths
property tracker : cs.CoverageTracker
property classStore : Object

Class constructor($classStore : Object; $tracker : cs.CoverageTracker)
	This.originalCode:=New object
	This.instrumentedMethods:=New collection
	This.tracker:=$tracker
	This.classStore:=$classStore || cs
	
Function instrumentMethod($methodPath : Text) : Boolean
	// Instrument a single method
	// $methodPath format: "ClassName.methodName" or "ProjectMethod"
	
	var $originalCode : Text
	var $instrumentedCode : Text
	var $success : Boolean
	
	// Get original code
	METHOD GET CODE($methodPath; $originalCode; *)
	
	If ($originalCode="")
		return False  // Method not found or empty
	End if 
	
	// Store original code for restoration
	This.originalCode[$methodPath]:=$originalCode
	
	// Instrument the code
	$instrumentedCode:=This._instrumentCode($originalCode; $methodPath)
	
	// Set instrumented code
	METHOD SET CODE($methodPath; $instrumentedCode; *)
	
	// Verify instrumentation succeeded
	var $verifyCode : Text
	METHOD GET CODE($methodPath; $verifyCode; *)
	$success:=($verifyCode=$instrumentedCode)
	
	If ($success)
		This.instrumentedMethods.push($methodPath)
	End if 
	
	return $success
	
Function instrumentClass($className : Text) : Integer
	// Instrument all methods in a class
	// Returns number of methods instrumented
	
	var $count : Integer
	$count:=0
	
	var $class : 4D.Class
	$class:=This.classStore[$className]
	
	If ($class=Null)
		return 0
	End if 
	
	// Get all function names from the class
	var $functions : Collection
	$functions:=This._getClassFunctions($class)
	
	var $functionName : Text
	For each ($functionName; $functions)
		var $methodPath : Text
		$methodPath:=$className+"."+$functionName
		
		If (This.instrumentMethod($methodPath))
			$count+=1
		End if 
	End for each 
	
	return $count
	
Function instrumentAllHostClasses() : Integer
	// Instrument all classes in the host project (excluding test classes)
	// Returns number of methods instrumented
	
	var $count : Integer
	$count:=0
	
	var $className : Text
	For each ($className; This.classStore)
		// Skip test classes
		If ($className="@Test")
			continue
		End if 
		
		// Skip framework classes
		If (This._isFrameworkClass($className))
			continue
		End if 
		
		// Skip DataClasses
		var $class : 4D.Class
		$class:=This.classStore[$className]
		If (($class.superclass#Null) && ($class.superclass.name="DataClass"))
			continue
		End if 
		
		$count+=This.instrumentClass($className)
	End for each 
	
	return $count
	
Function restoreAll()
	// Restore all instrumented methods to their original code
	
	var $methodPath : Text
	For each ($methodPath; This.instrumentedMethods)
		If (This.originalCode[$methodPath]#Null)
			METHOD SET CODE($methodPath; This.originalCode[$methodPath]; *)
		End if 
	End for each 
	
	// Clear tracking
	This.instrumentedMethods:=New collection
	This.originalCode:=New object
	
Function _instrumentCode($code : Text; $methodPath : Text) : Text
	// Instrument code by injecting coverage tracking calls
	
	var $lines : Collection
	$lines:=Split string($code; "\r\n")
	
	var $instrumentedLines : Collection
	$instrumentedLines:=New collection
	
	var $lineNum : Integer
	var $line : Text
	
	For ($lineNum; 0; $lines.length-1)
		$line:=$lines[$lineNum]
		$instrumentedLines.push($line)
		
		// Check if this is an executable line (not comment, not blank)
		If (This._isExecutableLine($line))
			// Inject tracking call after this line
			var $trackingCall : Text
			$trackingCall:=This._generateTrackingCall($methodPath; $lineNum+1)
			$instrumentedLines.push($trackingCall)
		End if 
	End for 
	
	return $instrumentedLines.join("\r\n")
	
Function _isExecutableLine($line : Text) : Boolean
	// Determine if a line is executable (not a comment or blank line)
	
	var $trimmed : Text
	$trimmed:=This._trim($line)
	
	// Empty line
	If ($trimmed="")
		return False
	End if 
	
	// Comment line
	If (($trimmed="//@@") || ($trimmed="//@"))
		return False
	End if 
	
	// Property declaration
	If ($trimmed="property @")
		return False
	End if 
	
	// Class constructor signature
	If ($trimmed="Class constructor@")
		return False
	End if 
	
	// Function signature
	If ($trimmed="Function @")
		return False
	End if 
	
	// End case, End for, End if, etc.
	If (($trimmed="End @") || ($trimmed="End if") || ($trimmed="End case") || ($trimmed="End for") || ($trimmed="End while") || ($trimmed="End use"))
		return False
	End if 
	
	// Else, Else if
	If (($trimmed="Else") || ($trimmed="Else @") || ($trimmed=": @"))
		return False
	End if 
	
	return True
	
Function _generateTrackingCall($methodPath : Text; $lineNumber : Integer) : Text
	// Generate the tracking call to inject
	// Use Storage directly for performance
	
	var $call : Text
	$call:="If (Storage.coverage#Null) : Use (Storage.coverage) : "
	$call:=$call+"If (Storage.coverage.data[\""+$methodPath+"\"]=Null) : "
	$call:=$call+"Storage.coverage.data[\""+$methodPath+"\"]:=New shared object(\"lines\"; New shared collection) : End if : "
	$call:=$call+"Use (Storage.coverage.data[\""+$methodPath+"\"]) : "
	$call:=$call+"If (Storage.coverage.data[\""+$methodPath+"\"].lines.indexOf("+String($lineNumber)+")=-1) : "
	$call:=$call+"Storage.coverage.data[\""+$methodPath+"\"].lines.push("+String($lineNumber)+") : "
	$call:=$call+"End if : End use : End use : End if"
	
	return $call
	
Function _getClassFunctions($class : 4D.Class) : Collection
	// Get all function names from a class
	// This is a simplified version - in production, you'd need to parse the class definition
	
	var $functions : Collection
	$functions:=New collection
	
	// Get class code to parse function names
	var $className : Text
	$className:=$class.name
	
	var $classCode : Text
	METHOD GET CODE($className; $classCode; *)
	
	If ($classCode="")
		return $functions
	End if 
	
	// Parse function declarations
	var $lines : Collection
	$lines:=Split string($classCode; "\r\n")
	
	var $line : Text
	For each ($line; $lines)
		var $trimmed : Text
		$trimmed:=This._trim($line)
		
		If ($trimmed="Function @")
			// Extract function name
			var $funcName : Text
			$funcName:=This._extractFunctionName($trimmed)
			If ($funcName#"")
				$functions.push($funcName)
			End if 
		End if 
	End for each 
	
	return $functions
	
Function _extractFunctionName($line : Text) : Text
	// Extract function name from "Function name(...)" line
	
	var $trimmed : Text
	$trimmed:=This._trim($line)
	
	If ($trimmed="Function @")
		// Remove "Function " prefix
		$trimmed:=Substring($trimmed; 10)  // "Function " is 9 chars + 1
		
		// Find first space or (
		var $endPos : Integer
		var $spacePos : Integer
		var $parenPos : Integer
		
		$spacePos:=Position(" "; $trimmed)
		$parenPos:=Position("("; $trimmed)
		
		If ($spacePos=0)
			$spacePos:=99999
		End if 
		If ($parenPos=0)
			$parenPos:=99999
		End if 
		
		$endPos:=($spacePos<$parenPos) ? $spacePos : $parenPos
		
		If ($endPos=99999)
			return $trimmed
		Else 
			return Substring($trimmed; 1; $endPos-1)
		End if 
	End if 
	
	return ""
	
Function _trim($text : Text) : Text
	// Remove leading and trailing whitespace
	
	var $result : Text
	$result:=$text
	
	// Remove leading spaces
	While (($result#"") && (($result[[1]]=" ") || ($result[[1]]="\t")))
		$result:=Substring($result; 2)
	End while 
	
	// Remove trailing spaces
	While (($result#"") && (($result[[Length($result)]]=" ") || ($result[[Length($result)]]="\t")))
		$result:=Substring($result; 1; Length($result)-1)
	End while 
	
	return $result
	
Function _isFrameworkClass($className : Text) : Boolean
	// Check if a class is part of the testing framework
	
	var $frameworkClasses : Collection
	$frameworkClasses:=New collection(\
		"TestRunner"; "TestSuite"; "TestFunction"; "Testing"; "Assert"; \
		"CoverageTracker"; "CodeInstrumenter"; "CoverageReporter"; \
		"UnitStatsTracker"; "UnitStatsDetail"; "ParallelTestRunner"\
		)
	
	If ($frameworkClasses.indexOf($className)#-1)
		return True
	End if 
	
	// Check if starts with underscore (internal test classes)
	If ($className="_@")
		return True
	End if 
	
	return False
