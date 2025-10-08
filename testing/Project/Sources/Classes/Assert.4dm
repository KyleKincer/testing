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


