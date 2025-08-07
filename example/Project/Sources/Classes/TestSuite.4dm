property class : 4D:C1709.Class
property classInstance : 4D:C1709.Object
property testFunctions : Collection  // Collection of cs.TestFunction

Class constructor($class : 4D:C1709.Class)
	This:C1470.class:=$class
	This:C1470.classInstance:=This:C1470.class.new()
	This:C1470.testFunctions:=[]
	
	This:C1470.discoverTests()
	
Function run()
	var $testFunction : cs:C1710.TestFunction
	For each ($testFunction; This:C1470.testFunctions)
		$testFunction.run()
	End for each 
	
Function discoverTests()
	var $testFunctions : Collection
	$testFunctions:=This:C1470._getTestClassFunctions()
	
	var $function : Object
	For each ($function; $testFunctions)
		This:C1470.testFunctions.push(cs:C1710.TestFunction.new(This:C1470.class; This:C1470.classInstance; $function.function; $function.name))
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