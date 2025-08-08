property class : 4D:C1709.Class
property classInstance : 4D:C1709.Object
property testFunctions : Collection  // Collection of cs.TestFunction
property outputFormat : Text  // "human" or "json"
property testPatterns : Collection  // Collection of test patterns for filtering

Class constructor($class : 4D:C1709.Class; $outputFormat : Text; $testPatterns : Collection)
	This:C1470.class:=$class
	This:C1470.classInstance:=This:C1470.class.new()
	This:C1470.testFunctions:=[]
	This:C1470.outputFormat:=$outputFormat || "human"
	This:C1470.testPatterns:=$testPatterns || []
	
	This:C1470.discoverTests()
	
Function run()
	This:C1470._callSetup()
	
	var $testFunction : cs:C1710.TestFunction
	For each ($testFunction; This:C1470.testFunctions)
		This:C1470._callBeforeEach()
		$testFunction.run()
		This:C1470._callAfterEach()
	End for each 
	
	This:C1470._callTeardown() 
	
Function discoverTests()
	var $testFunctions : Collection
	$testFunctions:=This:C1470._getTestClassFunctions()
	
	var $function : Object
	For each ($function; $testFunctions)
		// Filter individual test methods based on patterns
		If (This:C1470._shouldIncludeTestMethod($function.name))
			This:C1470.testFunctions.push(cs:C1710.TestFunction.new(This:C1470.class; This:C1470.classInstance; $function.function; $function.name))
		End if 
	End for each 
	
Function _getTestClassFunctions() : Collection
	// Returns collection of {function: 4D.Function; name: String}
	var $testFunctionNames : Collection
	$testFunctionNames:=This:C1470._getTestClassFunctionNames()
	
	var $testFunctions : Collection
	$testFunctions:=[]
	var $functionName : Text
	For each ($functionName; $testFunctionNames)
		If (This:C1470.classInstance[$functionName]#Null:C1517) && (OB Instance of:C1731(This:C1470.classInstance[$functionName]; 4D:C1709.Function))
			$testFunctions.push({\
				function: (This:C1470.classInstance[$functionName]); \
				name: $functionName\
				})
		End if 
	End for each 
	
	return $testFunctions
	
Function _getTestClassFunctionNames() : Collection
	var $functions : Collection
	$functions:=This:C1470._getClassFunctionNames()
	
	return $functions.filter(Formula:C1597($1.value="test_@"))
	
Function _getClassFunctionNames() : Collection
	var $code : Text
	$code:=This:C1470._getClassCode()
	
	return This:C1470._parseFunctionNames($code)
	
Function _getClassCode() : Text
	var $path; $code : Text
	$path:="[class]/"+This:C1470.class.name
	METHOD GET CODE:C1190($path; $code; *)
	return $code
	
Function _getCodeLines($code : Text) : Collection
	var $lines : Collection
	$lines:=Split string:C1554($code; Char:C90(Carriage return:K15:38))
	return $lines
	
Function _parseFunctionNames($code : Text) : Collection
	var $lines : Collection
	$lines:=This:C1470._getCodeLines($code)
	
	$lines:=This:C1470._getFunctionDeclarationLines($lines)
	
	var $functionNames : Collection
	$functionNames:=This:C1470._getFunctionNamesForDeclarations($lines)
	return $functionNames
	
Function _getFunctionDeclarationLines($lines : Collection) : Collection
	// Get lines that look like function declarations
	return $lines.filter(Formula:C1597($1.value="Function @"))
	
Function _getFunctionNamesForDeclarations($lines : Collection) : Collection
	$lines:=This:C1470._stripFunctionPrefixFromLines($lines)
	return This:C1470._stripFunctionParametersFromLines($lines)
	
Function _stripFunctionPrefixFromLines($lines : Collection) : Collection
	// Remove "Function " from all lines
	// E.g. "Function _myFunction($param1 : Text)" -> "_myFunction($param1 : Text)"
	return $lines.map(Formula:C1597(Substring:C12($1.value; 10)))
	
Function _stripFunctionParametersFromLines($lines : Collection) : Collection
	// Get only function name, removing parameters and return type
	// E.g. "_myFunction($param1 : Text)" -> "_myFunction"
	return $lines.map(Formula:C1597(\
		Substring:C12(\
		$1.value; \
		0; \
		Position:C15("("; $1.value)=-1 ? Length:C16($1.value) : Position:C15("("; $1.value)-1\
		)\
		))

Function _callSetup()
	If (This:C1470._hasMethod("setup"))
		This:C1470.classInstance.setup()
	End if 

Function _callTeardown()
	If (This:C1470._hasMethod("teardown"))
		This:C1470.classInstance.teardown()
	End if 

Function _callBeforeEach()
	If (This:C1470._hasMethod("beforeEach"))
		This:C1470.classInstance.beforeEach()
	End if 

Function _callAfterEach()
	If (This:C1470._hasMethod("afterEach"))
		This:C1470.classInstance.afterEach()
	End if 

Function _hasMethod($methodName : Text) : Boolean
	return (This:C1470.classInstance[$methodName]#Null:C1517) && (OB Instance of:C1731(This:C1470.classInstance[$methodName]; 4D:C1709.Function))
	
Function _shouldIncludeTestMethod($methodName : Text) : Boolean
	// If no patterns specified, include all tests
	If (This:C1470.testPatterns.length=0)
		return True:C214
	End if 
	
	var $pattern : Text
	For each ($pattern; This:C1470.testPatterns)
		// If pattern matches suite name exactly, include all methods in this suite
		If (This:C1470._matchesPattern(This:C1470.class.name; $pattern))
			return True:C214
		End if 
		
		var $fullTestName : Text
		$fullTestName:=This:C1470.class.name+"."+$methodName
		
		// Check if pattern matches method name or full test name
		If (This:C1470._matchesPattern($methodName; $pattern)) || (This:C1470._matchesPattern($fullTestName; $pattern))
			return True:C214
		End if 
	End for each 
	
	return False:C215
	
Function _matchesPattern($text : Text; $pattern : Text) : Boolean
	// Simple pattern matching with * wildcards
	If ($pattern="*")
		return True:C214
	End if 
	
	// Exact match
	If ($text=$pattern)
		return True:C214
	End if 
	
	// Replace * with @ for 4D wildcard matching
	var $fourDPattern : Text
	$fourDPattern:=Replace string:C233($pattern; "*"; "@")
	
	// Wildcard matching using 4D's @ operator
	If ($text=$fourDPattern)
		return True:C214
	End if 
	
	return False:C215