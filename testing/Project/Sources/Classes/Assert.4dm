Class constructor()
	
Function fail($t : Object; $message : Text; $expected : Variant; $actual : Variant)
	// Delegate to the test context's fail handler, preserving compatibility
	If (Count parameters:C259>=4)
		$t.fail($expected; $actual; $message)
	Else 
		$t.fail($message)
	End if 
	
Function areEqual($t : Object; $expected : Variant; $actual : Variant; $message : Text)
	// If values are not equal, fail and log message
	var $passed : Boolean
	$passed:=($expected=$actual)
	If ($passed)
		This:C1470._recordAssertion($t; True:C214; $expected; $actual; $message)
	Else 
		If (Count parameters:C259>=4)  // message provided
			$t.fail($expected; $actual; $message)
		Else 
			$t.fail($expected; $actual; "Assertion failed: values are not equal")
		End if 
	End if 
	
Function isTrue($t : Object; $value : Variant; $message : Text)
	var $passed : Boolean
	$passed:=$value
	If ($passed)
		This:C1470._recordAssertion($t; True:C214; True:C214; $value; $message)
	Else 
		If (Count parameters:C259>=3)
			$t.fail(True:C214; $value; $message)
		Else 
			$t.fail(True:C214; $value; "Assertion failed: value is not true")
		End if 
	End if 
	
Function isFalse($t : Object; $value : Variant; $message : Text)
	var $passed : Boolean
	$passed:=Not:C34($value)
	If ($passed)
		This:C1470._recordAssertion($t; True:C214; False:C215; $value; $message)
	Else 
		If (Count parameters:C259>=3)
			$t.fail(False:C215; $value; $message)
		Else 
			$t.fail(False:C215; $value; "Assertion failed: value is not false")
		End if 
	End if 
	
Function isNull($t : Object; $value : Variant; $message : Text)
	var $passed : Boolean
	$passed:=($value=Null:C1517)
	If ($passed)
		This:C1470._recordAssertion($t; True:C214; Null:C1517; $value; $message)
	Else 
		If (Count parameters:C259>=3)
			$t.fail(Null:C1517; $value; $message)
		Else 
			$t.fail(Null:C1517; $value; "Assertion failed: value is not Null")
		End if 
	End if 
	
Function isNotNull($t : Object; $value : Variant; $message : Text)
	var $passed : Boolean
	$passed:=($value#Null:C1517)
	If ($passed)
		This:C1470._recordAssertion($t; True:C214; "<not null>"; $value; $message)
	Else 
		If (Count parameters:C259>=3)
			$t.fail("<not null>"; $value; $message)
		Else 
			$t.fail("<not null>"; $value; "Assertion failed: value is Null")
		End if 
	End if 
	
Function contains($t : Object; $container : Variant; $value : Variant; $message : Text)
	var $found : Boolean
	var $type : Integer
	$found:=False:C215
	$type:=Value type:C1509($container)
	
	Case of 
		: ($type=Is text:K8:3)
			$found:=(Position:C15(String:C10($value); $container)>0)
		: ($type=Is collection:K8:32)
			$found:=($container.indexOf($value)#-1)
		Else 
			If (Count parameters:C259>=4)
				$t.fail($value; $container; $message)
			Else 
				$t.fail($value; $container; "Assertion failed: unsupported type for contains")
			End if 
			return 
	End case 
	
	If ($found)
		This:C1470._recordAssertion($t; True:C214; $value; $container; $message)
	Else 
		If (Count parameters:C259>=4)
			$t.fail($value; $container; $message)
		Else 
			$t.fail($value; $container; "Assertion failed: container does not contain value")
		End if 
	End if 
	
Function areDeepEqual($t : Object; $expected : Variant; $actual : Variant; $message : Text; $maxDepth : Integer)
	// Deep equality comparison for objects and collections with max-depth limiting
	// $maxDepth: Maximum recursion depth (default: 10)
	var $result : Object
	var $failureMessage : Text
	var $differences : Collection
	var $diff : Object
	var $i : Integer
	var $depth : Integer

	// Initialize to Null to clear any stale data from previous assertions
	$t.lastDeepEqualDifferences:=Null:C1517

	// Set default max depth if not provided
	If (Count parameters:C259>=5)
		$depth:=$maxDepth
	Else
		$depth:=10
	End if

	$result:=This:C1470._deepEqualCollectAll($expected; $actual; 0; ""; $depth)
	
	If ($result.equal)
		This:C1470._recordAssertion($t; True:C214; $expected; $actual; $message)
	Else 
		$differences:=$result.differences
		
		// Build detailed failure message with all differences
		If ($differences.length>0)
			var $diffCount : Text
			$diffCount:=String:C10($differences.length)
			$failureMessage:="Found "+$diffCount+" difference(s):\n"
			
			For ($i; 0; $differences.length-1)
				$diff:=$differences[$i]
				
				// Build line number
				var $lineNum : Text
				$lineNum:=String:C10($i+1)
				
				// Get path (already a string from our diff creation)
				var $pathDisplay : Text
				If ($diff.path="")
					$pathDisplay:="<root>"
				Else 
					$pathDisplay:=$diff.path
				End if 
				
				// Start building the line
				var $line : Text
				$line:="  ["+$lineNum+"] "+$diff.type+" at path: "+$pathDisplay
				
				// Add type-specific details
				Case of 
					: ($diff.type="different_value")
						// Values are already in the diff object
						var $expFormatted; $actFormatted : Text
						$expFormatted:=This:C1470._formatValue($diff.expected)
						$actFormatted:=This:C1470._formatValue($diff.actual)
						$line:=$line+" (expected: "+$expFormatted+", actual: "+$actFormatted+")"
						
					: ($diff.type="missing_key")
						$line:=$line+" (key missing in actual)"
						
					: ($diff.type="extra_key")
						$line:=$line+" (extra key in actual)"
						
					: ($diff.type="different_type")
						$line:=$line+" (expected type: "+$diff.expectedType+", actual type: "+$diff.actualType+")"
						
					: ($diff.type="different_length")
						var $expLen; $actLen : Text
						$expLen:=String:C10($diff.expectedLength)
						$actLen:=String:C10($diff.actualLength)
						$line:=$line+" (expected length: "+$expLen+", actual length: "+$actLen+")"

					: ($diff.type="max_depth_exceeded")
						var $maxDepthStr; $actualDepthStr : Text
						$maxDepthStr:=String:C10($diff.maxDepth)
						$actualDepthStr:=String:C10($diff.actualDepth)
						$line:=$line+" (max depth "+$maxDepthStr+" exceeded at depth "+$actualDepthStr+"). Increase maxDepth parameter to compare deeper."
				End case 
				
				// Add to message
				$failureMessage:=$failureMessage+$line
				
				// Add newline if not last item
				If ($i<($differences.length-1))
					$failureMessage:=$failureMessage+"\n"
				End if 
			End for 
			
			// Prepend custom message if provided
			If (Count parameters:C259>=4) && ($message#"")
				$failureMessage:=$message+"\n"+$failureMessage
			End if 
			
			// Store sanitized differences for programmatic access
			// Sanitize the differences collection to avoid storing complex objects
			var $sanitizedDifferences : Collection
			$sanitizedDifferences:=New collection:C1472
			For ($i; 0; $differences.length-1)
				var $sanitizedDiff : Object
				$diff:=$differences[$i]
				$sanitizedDiff:=New object:C1471("type"; $diff.type; "path"; $diff.path)
				
				Case of 
					: ($diff.type="different_value")
						$sanitizedDiff.expected:=This:C1470._sanitizeValue($diff.expected)
						$sanitizedDiff.actual:=This:C1470._sanitizeValue($diff.actual)
					: ($diff.type="missing_key")
						$sanitizedDiff.expected:=This:C1470._sanitizeValue($diff.expected)
					: ($diff.type="extra_key")
						$sanitizedDiff.actual:=This:C1470._sanitizeValue($diff.actual)
					: ($diff.type="different_type")
						$sanitizedDiff.expectedType:=$diff.expectedType
						$sanitizedDiff.actualType:=$diff.actualType
					: ($diff.type="different_length")
						$sanitizedDiff.expectedLength:=$diff.expectedLength
						$sanitizedDiff.actualLength:=$diff.actualLength
					: ($diff.type="max_depth_exceeded")
						$sanitizedDiff.maxDepth:=$diff.maxDepth
						$sanitizedDiff.actualDepth:=$diff.actualDepth
				End case 
				
				$sanitizedDifferences.push($sanitizedDiff)
			End for 
			$t.lastDeepEqualDifferences:=$sanitizedDifferences
		Else 
			If (Count parameters:C259>=4) && ($message#"")
				$failureMessage:=$message
			Else 
				$failureMessage:="Assertion failed: values are not deeply equal"
			End if 
		End if 
		
		// Call fail with just the message for deep equal failures
		// The failure message already contains all the detailed information
		$t.fail($failureMessage)
	End if 
	
Function _recordAssertion($t : Object; $passed : Boolean; $expected : Variant; $actual : Variant; $message : Text; $callChain : Collection)
	// Note: Line numbers from 4D's call chain are not reliable for showing source line locations
	// They reference internal function offsets rather than actual source lines
	// Therefore, we omit line numbers from assertion records
	
	var $assertInfo : Object
	$assertInfo:=New object:C1471(\
		"passed"; $passed; \
		"expected"; This:C1470._sanitizeValue($expected); \
		"actual"; This:C1470._sanitizeValue($actual); \
		"message"; $message\
		)
	$t.assertions.push($assertInfo)
	
Function _sanitizeValue($value : Variant) : Variant
	var $type : Integer
	$type:=Value type:C1509($value)
	
	// Use placeholders for complex structures to avoid serialization errors
	Case of 
		: ($type=Is object:K8:27)
			return "<object>"
		: ($type=Is collection:K8:32)
			return "<collection>"
		Else 
			return $value
	End case 
	
Function _formatValue($value : Variant) : Text
	// Format a value for display in error messages
	var $type : Integer
	$type:=Value type:C1509($value)
	
	Case of 
		: ($value=Null:C1517)
			return "null"
		: ($type=Is text:K8:3)
			return "\""+$value+"\""
		: ($type=Is real:K8:4) | ($type=Is longint:K8:6)
			return String:C10($value)
		: ($type=Is boolean:K8:9)
			If ($value)
				return "true"
			Else 
				return "false"
			End if 
		: ($type=Is object:K8:27)
			return "<object>"
		: ($type=Is collection:K8:32)
			return "<collection["+String:C10($value.length)+"]>"
		: ($type=Is date:K8:7)
			return String:C10($value; ISO date:K1:8)
		Else 
			return String:C10($value)
	End case 
	
Function _deepEqualCollectAll($expected : Variant; $actual : Variant; $depth : Integer; $currentPath : Text; $maxDepth : Integer) : Object
	// Recursive deep equality comparison that collects ALL differences
	var $expectedType; $actualType : Integer
	var $i : Integer
	var $expectedKeys; $actualKeys : Collection
	var $key : Text
	var $result : Object
	var $newPath : Text
	var $differences : Collection
	var $diff : Object

	$differences:=New collection:C1472

	// Check depth limit - fail the comparison if exceeded
	If ($depth>$maxDepth)
		$diff:=New object:C1471(\
			"type"; "max_depth_exceeded"; \
			"path"; $currentPath; \
			"maxDepth"; $maxDepth; \
			"actualDepth"; $depth\
			)
		$differences.push($diff)
		return New object:C1471("equal"; False:C215; "differences"; $differences)
	End if 
	
	$expectedType:=Value type:C1509($expected)
	$actualType:=Value type:C1509($actual)
	
	// Different types
	If ($expectedType#$actualType)
		var $expectedTypeName; $actualTypeName : Text
		$expectedTypeName:=This:C1470._getTypeName($expectedType)
		$actualTypeName:=This:C1470._getTypeName($actualType)
		$diff:=New object:C1471("type"; "different_type"; "path"; $currentPath; "expectedType"; $expectedTypeName; "actualType"; $actualTypeName)
		$differences.push($diff)
		return New object:C1471("equal"; False:C215; "differences"; $differences)
	End if 
	
	Case of 
		: ($expectedType=Is object:K8:27)
			// Check for Null objects
			If ($expected=Null:C1517) || ($actual=Null:C1517)
				If (($expected=Null:C1517) && ($actual=Null:C1517))
					return New object:C1471("equal"; True:C214; "differences"; $differences)
				Else 
					$diff:=New object:C1471("type"; "different_value"; "path"; $currentPath; "expected"; Null:C1517; "actual"; $actual)
					$differences.push($diff)
					return New object:C1471("equal"; False:C215; "differences"; $differences)
				End if 
			End if 
			
			// Get all keys from both objects
			$expectedKeys:=OB Keys:C1719($expected)
			$actualKeys:=OB Keys:C1719($actual)
			
			// Check for missing keys in actual
			For ($i; 0; $expectedKeys.length-1)
				$key:=$expectedKeys[$i]
				If (Not:C34(OB Is defined:C1231($actual; $key)))
					If ($currentPath="")
						$newPath:=$key
					Else 
						$newPath:=$currentPath+"."+$key
					End if 
					var $expectedValue : Variant
					$expectedValue:=OB Get:C1224($expected; $key)
					$diff:=New object:C1471("type"; "missing_key"; "path"; $newPath; "expected"; $expectedValue)
					$differences.push($diff)
				End if 
			End for 
			
			// Check for extra keys in actual
			For ($i; 0; $actualKeys.length-1)
				$key:=$actualKeys[$i]
				If (Not:C34(OB Is defined:C1231($expected; $key)))
					If ($currentPath="")
						$newPath:=$key
					Else 
						$newPath:=$currentPath+"."+$key
					End if 
					var $actualValue : Variant
					$actualValue:=OB Get:C1224($actual; $key)
					$diff:=New object:C1471("type"; "extra_key"; "path"; $newPath; "actual"; $actualValue)
					$differences.push($diff)
				End if 
			End for 
			
			// Compare matching keys recursively
			For ($i; 0; $expectedKeys.length-1)
				$key:=$expectedKeys[$i]
				
				If (OB Is defined:C1231($actual; $key))
					// Build path
					If ($currentPath="")
						$newPath:=$key
					Else 
						$newPath:=$currentPath+"."+$key
					End if 
					
					// Recursive comparison
					$result:=This:C1470._deepEqualCollectAll(OB Get:C1224($expected; $key); OB Get:C1224($actual; $key); $depth+1; $newPath; $maxDepth)
					If (Not:C34($result.equal))
						// Merge differences from recursive call
						var $j : Integer
						For ($j; 0; $result.differences.length-1)
							$differences.push($result.differences[$j])
						End for 
					End if 
				End if 
			End for 
			
			return New object:C1471("equal"; ($differences.length=0); "differences"; $differences)
			
		: ($expectedType=Is collection:K8:32)
			// Check for Null collections
			If ($expected=Null:C1517) || ($actual=Null:C1517)
				If (($expected=Null:C1517) && ($actual=Null:C1517))
					return New object:C1471("equal"; True:C214; "differences"; $differences)
				Else 
					$diff:=New object:C1471("type"; "different_value"; "path"; $currentPath; "expected"; Null:C1517; "actual"; $actual)
					$differences.push($diff)
					return New object:C1471("equal"; False:C215; "differences"; $differences)
				End if 
			End if 
			
			// Different lengths
			If ($expected.length#$actual.length)
				var $expectedLength; $actualLength : Integer
				$expectedLength:=$expected.length
				$actualLength:=$actual.length
				$diff:=New object:C1471("type"; "different_length"; "path"; $currentPath; "expectedLength"; $expectedLength; "actualLength"; $actualLength)
				$differences.push($diff)
				// Continue comparing elements up to the shorter length
			End if 
			
			// Compare each element
			var $maxLength : Integer
			If ($expected.length<$actual.length)
				$maxLength:=$expected.length
			Else 
				$maxLength:=$actual.length
			End if 
			
			For ($i; 0; $maxLength-1)
				// Build path
				If ($currentPath="")
					$newPath:="["+String:C10($i)+"]"
				Else 
					$newPath:=$currentPath+"["+String:C10($i)+"]"
				End if 
				
				$result:=This:C1470._deepEqualCollectAll($expected[$i]; $actual[$i]; $depth+1; $newPath; $maxDepth)
				If (Not:C34($result.equal))
					var $k : Integer
					For ($k; 0; $result.differences.length-1)
						$differences.push($result.differences[$k])
					End for 
				End if 
			End for 
			
			return New object:C1471("equal"; ($differences.length=0); "differences"; $differences)
			
		Else 
			// For primitives, compare directly
			If ($expected=$actual)
				return New object:C1471("equal"; True:C214; "differences"; $differences)
			Else 
				$diff:=New object:C1471("type"; "different_value"; "path"; $currentPath; "expected"; $expected; "actual"; $actual)
				$differences.push($diff)
				return New object:C1471("equal"; False:C215; "differences"; $differences)
			End if 
	End case 
	
Function _getTypeName($type : Integer) : Text
	// Convert type constant to readable name
	Case of 
		: ($type=Is text:K8:3)
			return "text"
		: ($type=Is real:K8:4)
			return "number"
		: ($type=Is longint:K8:6)
			return "integer"
		: ($type=Is boolean:K8:9)
			return "boolean"
		: ($type=Is object:K8:27)
			return "object"
		: ($type=Is collection:K8:32)
			return "collection"
		: ($type=Is date:K8:7)
			return "date"
		: ($type=Is time:K8:8)
			return "time"
		Else 
			return "unknown"
	End case 
	
	
	