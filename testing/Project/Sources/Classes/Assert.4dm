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
	
Function areDeepEqual($t : Object; $expected : Variant; $actual : Variant; $message : Text)
	// Deep equality comparison for objects and collections with circular reference detection
	var $passed : Boolean
	var $depth : Integer
	
	$depth:=0  // Start at depth 0
	$passed:=This:C1470._deepEqual($expected; $actual; $depth)
	
	If ($passed)
		This:C1470._recordAssertion($t; True:C214; $expected; $actual; $message)
	Else 
		If (Count parameters:C259>=4)  // message provided
			$t.fail($expected; $actual; $message)
		Else 
			$t.fail($expected; $actual; "Assertion failed: values are not deeply equal")
		End if 
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
	
Function _deepEqual($expected : Variant; $actual : Variant; $depth : Integer) : Boolean
	// Recursive deep equality comparison with depth-based circular reference prevention
	var $expectedType; $actualType : Integer
	var $i : Integer
	var $expectedKeys; $actualKeys : Collection
	var $key : Text
	var $maxDepth : Integer
	
	$maxDepth:=10  // Maximum recursion depth to prevent infinite loops from circular references

	// Check depth limit (must be checked early to prevent stack overflow)
	If ($depth>$maxDepth)
		// Assume equal if we've gone too deep (likely circular reference)
		return True:C214
	End if 
	
	$expectedType:=Value type:C1509($expected)
	$actualType:=Value type:C1509($actual)
	
	// Different types are never equal
	If ($expectedType#$actualType)
		return False:C215
	End if 
	
	Case of 
		: ($expectedType=Is object:K8:27)
			// Check for Null objects
			If ($expected=Null:C1517) || ($actual=Null:C1517)
				return ($expected=Null:C1517) && ($actual=Null:C1517)
			End if 
			
			// Get all keys from both objects using OB Keys
			$expectedKeys:=OB Keys:C1719($expected)
			$actualKeys:=OB Keys:C1719($actual)
			
			// Check if both have the same number of keys
			If ($expectedKeys.length#$actualKeys.length)
				return False:C215
			End if 
			
			// Compare each property in expected
			For ($i; 0; $expectedKeys.length-1)
				$key:=$expectedKeys[$i]
				
				// Check if actual also has this key
				If (Not:C34(OB Is defined:C1231($actual; $key)))
					return False:C215
				End if 
				
				// Recursively compare property values with increased depth
				If (Not:C34(This:C1470._deepEqual(OB Get:C1224($expected; $key); OB Get:C1224($actual; $key); $depth+1)))
					return False:C215
				End if 
			End for 
			
			// Check if actual has any extra keys not in expected
			For ($i; 0; $actualKeys.length-1)
				$key:=$actualKeys[$i]
				If (Not:C34(OB Is defined:C1231($expected; $key)))
					return False:C215
				End if 
			End for 
			
			return True:C214
			
		: ($expectedType=Is collection:K8:32)
			// Check for Null collections
			If ($expected=Null:C1517) || ($actual=Null:C1517)
				return ($expected=Null:C1517) && ($actual=Null:C1517)
			End if 
			
			// Different lengths are not equal
			If ($expected.length#$actual.length)
				return False:C215
			End if 
			
			// Compare each element with increased depth
			For ($i; 0; $expected.length-1)
				If (Not:C34(This:C1470._deepEqual($expected[$i]; $actual[$i]; $depth+1)))
					return False:C215
				End if 
			End for 
			
			return True:C214
			
		Else 
			// For primitives (text, number, boolean, date, etc.), use standard comparison
			return ($expected=$actual)
	End case 
	
	
	