property classStore : 4D:C1709.Object  // Class store from the calling project
property hostStorage : 4D:C1709.Object  // Host project's Storage for trigger control
property testSuites : Collection  // Collection of cs._TestSuite
property results : Object  // Test results summary
property outputFormat : Text  // "human", "json", "junit"
property verboseOutput : Boolean  // Whether to include detailed information
property callChainOutput : Boolean  // Terse JSON: call chain when verbose or callchain=true
property testPatterns : Collection  // Collection of test patterns to match
property includeTags : Collection  // Tags to include (OR logic)
property excludeTags : Collection  // Tags to exclude
property requireAllTags : Collection  // Tags that must all be present (AND logic)
property userParams : Object  // User parameters passed to the runner
property disableTriggersByDefault : Boolean  // Whether triggers are disabled by default
property consoleReport : Boolean  // Live progress + human report on stdout (human and junit formats)
property quietOutput : Boolean  // quiet=true: one line per test class instead of one per test
property debugOutput : Boolean  // debug=true: emit [DEBUG] trace lines
Class constructor($cs : 4D:C1709.Object; $hostStorage : 4D:C1709.Object; $userParams : Object)
	This:C1470.classStore:=$cs || cs:C1710
	This:C1470.hostStorage:=$hostStorage  // Can be Null for component-only testing
	This:C1470.userParams:=$userParams || This:C1470._parseUserParams()  // Use provided params or parse from command line
	This:C1470.testSuites:=[]
	This:C1470._initializeResults()
	This:C1470._determineOutputFormat()
	This:C1470._parseTestPatterns()
	This:C1470._parseTagFilters()
	This:C1470._determineTriggerDefaultBehavior()
	
Function run()
	This:C1470._initializeTriggerControl()
	This:C1470._prepareErrorHandlingStorage()
	var $handlerState : Object
	$handlerState:=This:C1470._installErrorHandler()
	This:C1470._debugLog("run: before _runInternal")
	This:C1470._runInternal()
	This:C1470._debugLog("run: after _runInternal")
	This:C1470._captureGlobalErrors()
	This:C1470._debugLog("run: after _captureGlobalErrors")
	This:C1470._generateReport()
	This:C1470._debugLog("run: after _generateReport")
	This:C1470._restoreErrorHandler($handlerState)
	
Function _logLine($text : Text; $messageType : Integer)
	// LOG EVENT treats stdout text as a printf format string, so "%" must be doubled
	var $type : Integer
	$type:=(Count parameters:C259>=2) ? $messageType : Information message:K38:1
	LOG EVENT:C667(Into system standard outputs:K38:9; Replace string:C233($text; "%"; "%%")+"\r\n"; $type)
	
Function _debugLog($text : Text)
	If (This:C1470.debugOutput)
		This:C1470._logLine("[DEBUG] "+$text)
	End if 
	
Function _isConsoleOutput() : Boolean
	// outputFormat may be overridden to "none" after construction (nested runners in tests)
	return This:C1470.consoleReport && ((This:C1470.outputFormat="human") || (This:C1470.outputFormat="junit"))
	
Function _effectiveParams() : Object
	// Command-line params overlaid with params passed to the constructor
	var $params : Object
	$params:=This:C1470._parseUserParams()
	If (This:C1470.userParams#Null:C1517)
		var $key : Text
		For each ($key; This:C1470.userParams)
			$params[$key]:=This:C1470.userParams[$key]
		End for each 
	End if 
	return $params
	
Function _determineTriggerDefaultBehavior()
	// Determine the default trigger behavior based on user parameters
	// Default is to disable triggers (testMode=true) unless explicitly enabled
	var $triggerParam : Text
	$triggerParam:=This:C1470.userParams.triggers || ""
	
	// triggers=enabled means triggers are ON by default (testMode=false)
	// triggers=disabled (or omitted) means triggers are OFF by default (testMode=true)
	This:C1470.disableTriggersByDefault:=($triggerParam#"enabled")
	
Function _initializeTriggerControl()
	// Initialize trigger control flag in the appropriate Storage
	var $storageToUse : 4D:C1709.Object
	$storageToUse:=(This:C1470.hostStorage#Null:C1517) ? This:C1470.hostStorage : Storage:C1525
	
	Use ($storageToUse)
		If ($storageToUse.triggersDisabled=Null:C1517)
			$storageToUse.triggersDisabled:=New shared object:C1526("testMode"; This:C1470.disableTriggersByDefault)
		Else 
			Use ($storageToUse.triggersDisabled)
				$storageToUse.triggersDisabled.testMode:=This:C1470.disableTriggersByDefault
			End use 
		End if 
	End use 
	
Function enableTriggersForTest()
	// Enable triggers for the current test (sets testMode=false)
	var $storageToUse : 4D:C1709.Object
	$storageToUse:=(This:C1470.hostStorage#Null:C1517) ? This:C1470.hostStorage : Storage:C1525
	
	Use ($storageToUse)
		If ($storageToUse.triggersDisabled#Null:C1517)
			Use ($storageToUse.triggersDisabled)
				$storageToUse.triggersDisabled.testMode:=False:C215
			End use 
		End if 
	End use 
	
Function disableTriggersForTest()
	// Disable triggers for the current test (sets testMode=true)
	var $storageToUse : 4D:C1709.Object
	$storageToUse:=(This:C1470.hostStorage#Null:C1517) ? This:C1470.hostStorage : Storage:C1525
	
	Use ($storageToUse)
		If ($storageToUse.triggersDisabled#Null:C1517)
			Use ($storageToUse.triggersDisabled)
				$storageToUse.triggersDisabled.testMode:=True:C214
			End use 
		End if 
	End use 
	
Function restoreDefaultTriggerBehavior()
	// Restore the default trigger behavior after a test
	var $storageToUse : 4D:C1709.Object
	$storageToUse:=(This:C1470.hostStorage#Null:C1517) ? This:C1470.hostStorage : Storage:C1525
	
	Use ($storageToUse)
		If ($storageToUse.triggersDisabled#Null:C1517)
			Use ($storageToUse.triggersDisabled)
				$storageToUse.triggersDisabled.testMode:=This:C1470.disableTriggersByDefault
			End use 
		End if 
	End use 
	
Function _prepareErrorHandlingStorage()
	Use (Storage:C1525)
		If (Storage:C1525.testErrors=Null:C1517)
			Storage:C1525.testErrors:=New shared collection:C1527
		Else 
			Storage:C1525.testErrors.clear()
		End if 
	End use 

	// Prepare host Storage for error collection (when running as a component,
	// the host's error handlers write to host Storage)
	If (This:C1470.hostStorage#Null:C1517)
		Use (This:C1470.hostStorage)
			If (This:C1470.hostStorage.testErrors=Null:C1517)
				This:C1470.hostStorage.testErrors:=New shared collection:C1527
			Else
				This:C1470.hostStorage.testErrors.clear()
			End if
		End use
	End if
	
Function _runInternal()
	This:C1470._prepareSuites()
	This:C1470._runSuitesSequentially()
	
Function _prepareSuites()
	This:C1470._initializeResults()
	This:C1470.testSuites:=[]
	This:C1470.discoverTests()
	
Function _runSuitesSequentially()
	This:C1470.results.startTime:=Milliseconds:C459
	
	If (This:C1470._isConsoleOutput())
		This:C1470._logHeader()
	End if 
	
	var $testSuite : cs:C1710._TestSuite
	var $suiteIndex : Integer
	$suiteIndex:=0
	For each ($testSuite; This:C1470.testSuites)
		$suiteIndex+=1
		This:C1470._debugLog("suite "+String:C10($suiteIndex)+"/"+String:C10(This:C1470.testSuites.length)+": "+$testSuite.class.name+" ("+String:C10($testSuite.testFunctions.length)+" tests)")
		$testSuite.run()
		This:C1470._collectSuiteResults($testSuite)
	End for each 
	This:C1470._debugLog("_runSuitesSequentially: all suites done")
	
	This:C1470.results.endTime:=Milliseconds:C459
	This:C1470.results.duration:=This:C1470.results.endTime-This:C1470.results.startTime
	
Function _installErrorHandler() : Object
	var $previousErrorHandler : Text
	var $previousGlobalHandler : Text
	var $shouldInstallLocal : Boolean
	var $shouldInstallGlobal : Boolean
	
	$previousErrorHandler:=Method called on error:C704
	$shouldInstallLocal:=($previousErrorHandler#"TestErrorHandler")
	
	If ($shouldInstallLocal)
		ON ERR CALL:C155("TestErrorHandler")
	End if 
	
	$previousGlobalHandler:=Method called on error:C704(1)
	$shouldInstallGlobal:=($previousGlobalHandler#"TestGlobalErrorHandler")
	
	If ($shouldInstallGlobal)
		ON ERR CALL:C155("TestGlobalErrorHandler"; 1)
	End if 
	
	return New object:C1471(\
		"previousHandler"; $previousErrorHandler; \
		"installedLocalHandler"; $shouldInstallLocal; \
		"previousGlobalHandler"; $previousGlobalHandler; \
		"installedGlobalHandler"; $shouldInstallGlobal\
		)
	
Function _restoreErrorHandler($handlerState : Object)
	If ($handlerState=Null:C1517)
		return 
	End if 
	
	If (Bool:C1537($handlerState.installedLocalHandler))
		var $previousErrorHandler : Text
		$previousErrorHandler:=$handlerState.previousHandler
		
		If ($previousErrorHandler#"")
			ON ERR CALL:C155($previousErrorHandler)
		Else 
			ON ERR CALL:C155("")
		End if 
	End if 
	
	If (Bool:C1537($handlerState.installedGlobalHandler))
		var $previousGlobalHandler : Text
		$previousGlobalHandler:=$handlerState.previousGlobalHandler
		
		If ($previousGlobalHandler#"")
			ON ERR CALL:C155($previousGlobalHandler; 1)
		Else 
			ON ERR CALL:C155(""; 1)
		End if 
	End if 
	
Function discoverTests()
	var $class : 4D:C1709.Class
	For each ($class; This:C1470._getTestClasses())
		var $testSuite : cs:C1710._TestSuite
		$testSuite:=cs:C1710._TestSuite.new($class; This:C1470.outputFormat; This:C1470.testPatterns; This:C1470)
		
		// Filter test suite based on patterns
		If (This:C1470._shouldIncludeTestSuite($testSuite))
			This:C1470.testSuites.push($testSuite)
		End if 
	End for each 
	
Function _getTestClasses()->$classes : Collection
	// Returns collection of 4D.Class
	var $classStore : Object
	$classStore:=This:C1470._getClassStore()
	
	return This:C1470._filterTestClasses($classStore)
	
Function _getClassStore() : Object
	// Extracted method to make testing easier - can be mocked
	return This:C1470.classStore
	
Function _filterTestClasses($classStore : Object) : Collection
	var $classes : Collection
	$classes:=[]
	var $className : Text
	For each ($className; $classStore)
		// Skip classes without superclass property (malformed classes)
		If ($classStore[$className].superclass=Null:C1517)
			continue
		End if 
		
		// Skip Dataclasses for now
		If ($classStore[$className].superclass.name="DataClass")
			continue
		End if 
		
		// Test classes end with "Test", e.g. "MyClassTest"
		If ($className="@Test")
			$classes.push($classStore[$className])
		End if 
	End for each 
	
	return $classes
	
Function _initializeResults()
	This:C1470.results:=New object:C1471(\
		"totalTests"; 0; \
		"passed"; 0; \
		"failed"; 0; \
		"skipped"; 0; \
		"startTime"; 0; \
		"endTime"; 0; \
		"duration"; 0; \
		"suites"; []; \
		"failedTests"; []; \
		"assertions"; 0; \
		"globalErrors"; []; \
		"hasGlobalErrors"; False:C215; \
		"globalErrorCount"; 0\
		)
	
Function _logHeader()
	This:C1470._logLine("")
	This:C1470._logLine("=== 4D Unit Testing Framework ===")
	This:C1470._logLine("Running tests...")
	This:C1470._logLine("")
	
Function _logSuiteHeader($suiteName : Text)
	If (This:C1470._isConsoleOutput()) && Not:C34(This:C1470.quietOutput)
		This:C1470._logLine($suiteName)
	End if 
	
Function _logLiveResult($testResult : Object)
	If (Not:C34(This:C1470._isConsoleOutput())) || (This:C1470.quietOutput)
		return 
	End if 
	
	Case of 
		: (Bool:C1537($testResult.skipped))
			If (Not:C34(This:C1470.quietOutput))
				This:C1470._logLine("  - "+$testResult.name+" (skipped)")
			End if 
		: (Bool:C1537($testResult.passed))
			If (Not:C34(This:C1470.quietOutput))
				This:C1470._logLine("  ✓ "+$testResult.name+" ("+String:C10($testResult.duration)+"ms)")
			End if 
		Else 
			var $lines : Collection
			$lines:=This:C1470._buildLiveFailureLines($testResult)
			var $line : Text
			For each ($line; $lines)
				This:C1470._logLine($line; Error message:K38:3)
			End for each 
	End case 
	
// quiet=true: one line per class, then the failed tests of a failing class
Function _logSuiteResult($suiteName : Text; $tests : Collection)
	If (Not:C34(This:C1470._isConsoleOutput())) || Not:C34(This:C1470.quietOutput)
		return 
	End if 
	
	var $line : Text
	For each ($line; This:C1470._buildQuietSuiteLines($suiteName; $tests))
		This:C1470._logLine($line)
	End for each 
	
Function _buildQuietSuiteLines($suiteName : Text; $tests : Collection) : Collection
	var $failed : Collection
	var $passed; $skipped : Integer
	$failed:=[]
	
	var $test : Object
	For each ($test; ($tests#Null:C1517) ? $tests : [])
		Case of 
			: (Bool:C1537($test.skipped))
				$skipped+=1
			: (Bool:C1537($test.passed))
				$passed+=1
			Else 
				$failed.push($test)
		End case 
	End for each 
	
	var $counts : Text
	$counts:=String:C10($passed)+" passed"
	If ($failed.length>0)
		$counts:=String:C10($failed.length)+" failed, "+$counts
	End if 
	If ($skipped>0)
		$counts+=", "+String:C10($skipped)+" skipped"
	End if 
	
	var $lines : Collection
	$lines:=[(($failed.length>0) ? "✗ " : "✓ ")+$suiteName+" ("+$counts+")"]
	For each ($test; $failed)
		$lines.combine(This:C1470._buildLiveFailureLines($test))
	End for each 
	return $lines
	
Function _buildLiveFailureLines($testResult : Object) : Collection
	var $lines : Collection
	$lines:=[]
	$lines.push("  ✗ "+This:C1470._qualifiedTestName($testResult)+" ("+String:C10($testResult.duration)+"ms)")
	
	var $reason : Text
	For each ($reason; This:C1470._describeFailure($testResult))
		$lines.push("      "+$reason)
	End for each 
	
	If (This:C1470.verboseOutput) && ($testResult.callChain#Null:C1517)
		$lines.combine(This:C1470._indentLines(This:C1470._formatCallChain($testResult.callChain); "      "))
	End if 
	
	return $lines
	
Function _qualifiedTestName($test : Object) : Text
	var $suite : Text
	$suite:=String:C10($test.suite)
	return ($suite#"") ? ($suite+"."+String:C10($test.name)) : String:C10($test.name)
	
Function _indentLines($text : Text; $indent : Text) : Collection
	var $lines : Collection
	$lines:=[]
	var $normalized : Text
	$normalized:=Replace string:C233($text; "\r\n"; "\n")
	$normalized:=Replace string:C233($normalized; "\r"; "\n")
	var $line : Text
	For each ($line; Split string:C1554($normalized; "\n"))
		If ($line#"")
			$lines.push($indent+$line)
		End if 
	End for each 
	return $lines
	
Function _collectSuiteResults($testSuite : cs:C1710._TestSuite)
	// Skip suites with no tests
	If ($testSuite.testFunctions.length=0)
		return 
	End if 
	
	This:C1470._logSuiteHeader($testSuite.class.name)
	
	var $suiteResult : Object
	$suiteResult:=New object:C1471(\
		"name"; $testSuite.class.name; \
		"tests"; []; \
		"passed"; 0; \
		"failed"; 0; \
		"skipped"; 0; \
		"assertions"; 0\
		)
	
	var $testFunction : cs:C1710._TestFunction
	For each ($testFunction; $testSuite.testFunctions)
		var $testResult : Object
		$testResult:=$testFunction.getResult()
		
		This:C1470.results.totalTests+=1
		
		If ($testResult.skipped)
			This:C1470.results.skipped+=1
			$suiteResult.skipped+=1
		Else 
			If ($testResult.passed)
				This:C1470.results.passed+=1
				$suiteResult.passed+=1
			Else 
				This:C1470.results.failed+=1
				$suiteResult.failed+=1
				This:C1470.results.failedTests.push($testResult)
			End if 
		End if 
		This:C1470._logLiveResult($testResult)
		
		$suiteResult.tests.push($testResult)
		This:C1470.results.assertions+=($testResult.assertionCount)
		$suiteResult.assertions+=($testResult.assertionCount)
	End for each 
	
	This:C1470._logSuiteResult($suiteResult.name; $suiteResult.tests)
	This:C1470.results.suites.push($suiteResult)
	
Function _captureGlobalErrors()
	var $globalErrors : Collection
	$globalErrors:=This:C1470._drainGlobalErrorsFromStorage()
	
	This:C1470.results.globalErrors:=$globalErrors
	This:C1470.results.globalErrorCount:=$globalErrors.length
	This:C1470.results.hasGlobalErrors:=Bool:C1537($globalErrors.length>0)
	
Function _drainGlobalErrorsFromStorage() : Collection
	var $globalErrors : Collection
	$globalErrors:=New collection:C1472
	
	If (Storage:C1525.testErrors#Null:C1517)
		Use (Storage:C1525.testErrors)
			var $index : Integer
			For ($index; Storage:C1525.testErrors.length-1; 0; -1)
				var $error : Object
				$error:=Storage:C1525.testErrors[$index]
				
				var $context : Text
				$context:=$error.context || ""
				
				If ($context="global")
					$globalErrors.push(OB Copy:C1225($error))
					Storage:C1525.testErrors.remove($index)
				End if 
			End for 
		End use 
	End if 

	// Drain from host Storage (when running as a component)
	If (This:C1470.hostStorage#Null:C1517) && (This:C1470.hostStorage.testErrors#Null:C1517)
		Use (This:C1470.hostStorage.testErrors)
			For ($index; This:C1470.hostStorage.testErrors.length-1; 0; -1)
				$error:=This:C1470.hostStorage.testErrors[$index]
				$context:=$error.context || ""

				If ($context="global")
					$globalErrors.push(OB Copy:C1225($error))
					This:C1470.hostStorage.testErrors.remove($index)
				End if
			End for
		End use
	End if
	
	return $globalErrors
	
Function _formatGlobalErrorForLog($error : Object) : Text
	var $processText : Text
	$processText:=($error.processNumber#Null) ? String($error.processNumber) : "?"
	return "- Process "+$processText+": "+This._formatRuntimeError($error)
	
Function _errorCodeText($error : Object) : Text
	If ($error.code=Null) || (Num($error.code)=0)
		return "?"
	End if 
	return String($error.code)
	
Function _errorTextField($error : Object; $field : Text) : Text
	If ($error[$field]=Null)
		return ""
	End if 
	return String($error[$field])
	
Function _formatRuntimeError($error : Object) : Text
	// Field mapping from TestErrorHandler: code=Error, text=Error method,
	// method=Error formula, line=Error line, message=Last errors[0].message
	var $result; $message; $methodName; $formula : Text
	$message:=This._errorTextField($error; "message")
	$methodName:=This._errorTextField($error; "text")
	$formula:=This._errorTextField($error; "method")
	
	$result:="Runtime error ["+This._errorCodeText($error)+"]"
	If ($message#"")
		$result:=$result+" "+$message
	End if 
	
	Case of 
		: ($methodName#"")
			$result:=$result+" — in "+$methodName
			If (Num($error.line)>0)
				$result:=$result+" line "+String($error.line)
			End if 
		: (Num($error.line)>0)
			$result:=$result+" — at line "+String($error.line)
	End case 
	
	If ($formula#"") && ($formula#$methodName)
		$result:=$result+" (formula: "+$formula+")"
	End if 
	
	return $result
	
Function _runtimeErrorSummary($error : Object) : Text
	// Compact form for the JUnit message attribute: [code] message (method:line)
	var $result; $message; $methodName : Text
	$message:=This._errorTextField($error; "message")
	$methodName:=This._errorTextField($error; "text")
	
	$result:="["+This._errorCodeText($error)+"]"
	If ($message#"")
		$result:=$result+" "+$message
	End if 
	If ($methodName#"")
		$result:=$result+" ("+$methodName
		If (Num($error.line)>0)
			$result:=$result+":"+String($error.line)
		End if 
		$result:=$result+")"
	End if 
	return $result
	
Function _formatAssertionFailure($assertion : Object) : Text
	var $result; $message : Text
	$result:="Assertion failed"
	If (Num($assertion.line)>0)
		$result:=$result+" at line "+String($assertion.line)
	End if 
	
	$message:=This._errorTextField($assertion; "message")
	If (Position("Assertion failed: "; $message; *)=1)
		$message:=Substring($message; 19)
	End if 
	If ($message#"")
		$result:=$result+": "+$message
	End if 
	
	If ($assertion.expected#Null) || ($assertion.actual#Null)
		$result:=$result+" (expected: "+This._formatValue($assertion.expected)+", actual: "+This._formatValue($assertion.actual)+")"
	End if 
	
	return $result
	
Function _formatValue($value : Variant) : Text
	var $type : Integer
	$type:=Value type($value)
	Case of 
		: ($type=Is null) || ($type=Is undefined)
			return "Null"
		: ($type=Is text)
			return "\""+$value+"\""
		: ($type=Is boolean)
			return $value ? "True" : "False"
		: ($type=Is object) || ($type=Is collection)
			return JSON Stringify($value)
		Else 
			return String($value)
	End case 
	
Function _describeFailure($test : Object) : Collection
	// Ordered reason lines: runtime errors first, then failed (non-synthetic) assertions
	var $reasons : Collection
	$reasons:=[]
	
	var $error : Object
	If ($test.runtimeErrors#Null)
		For each ($error; $test.runtimeErrors)
			$reasons.push(This._formatRuntimeError($error))
		End for each 
	End if 
	
	var $assertion : Object
	If ($test.assertions#Null)
		For each ($assertion; $test.assertions)
			If (Not(Bool($assertion.passed))) && (Not(Bool($assertion.isRuntimeError)))
				$reasons.push(This._formatAssertionFailure($assertion))
			End if 
		End for each 
	End if 
	
	If ($reasons.length=0)
		If ($test.logMessages#Null) && ($test.logMessages.length>0)
			$reasons.push(String($test.logMessages[0]))
		Else 
			$reasons.push("Test failed")
		End if 
	End if 
	
	return $reasons
	
Function _errorCallChain($error : Object; $test : Object) : Collection
	// Prefer the per-error snapshot from the error handler, else the test's failure chain
	var $json : Text
	$json:=This._errorTextField($error; "callChainJSON")
	If (Substring($json; 1; 1)="[")
		var $parsed : Variant
		$parsed:=JSON Parse($json)
		If (Value type($parsed)=Is collection)
			return $parsed
		End if 
	End if 
	If ($test#Null) && (Value type($test.callChain)=Is collection)
		return $test.callChain
	End if 
	return Null
	
Function _padRight($text : Text; $width : Integer) : Text
	var $result : Text
	$result:=$text
	While (Length($result)<$width)
		$result:=$result+" "
	End while 
	return $result
	
Function _generateReport()
	This._debugLog("_generateReport: format="+This.outputFormat)
	Case of 
		: (This.outputFormat="json")
			This._generateJSONReport()
		: (This.outputFormat="junit")
			This._generateJUnitXMLReport()
			This._generateHumanReport()
		: (This.outputFormat#"none")
			This._generateHumanReport()
	End case 
	This._debugLog("_generateReport: done")
	
Function _generateHumanReport()
	This._debugLog("_generateHumanReport: start")
	var $line : Text
	For each ($line; This._buildHumanReportLines())
		This._logLine($line)
	End for each 
	
Function _buildHumanReportLines() : Collection
	var $lines : Collection
	$lines:=[]
	$lines.combine(This._buildFailedTestsLines())
	$lines.combine(This._buildRuntimeErrorLines())
	$lines.combine(This._buildGlobalErrorLines())
	$lines.combine(This._buildSummaryLines())
	$lines.combine(This._buildFinalResultLines())
	return $lines
	
Function _buildSummaryLines() : Collection
	var $passRate : Real
	var $effectiveTotal : Integer
	$effectiveTotal:=This.results.totalTests-This.results.skipped
	If ($effectiveTotal>0)
		$passRate:=(This.results.passed/$effectiveTotal)*100
	Else 
		$passRate:=0
	End if 
	
	return [\
		""; \
		"=== Test Results Summary ==="; \
		"Total Tests: "+String(This.results.totalTests); \
		"Passed: "+String(This.results.passed); \
		"Failed: "+String(This.results.failed); \
		"Skipped: "+String(This.results.skipped); \
		"Assertions: "+String(This.results.assertions); \
		"Pass Rate: "+String($passRate; "##0.0")+"%"; \
		"Duration: "+String(This.results.duration)+"ms"; \
		"External Errors: "+String(This.results.globalErrorCount)\
		]
	
Function _buildFailedTestsLines() : Collection
	var $lines : Collection
	$lines:=[]
	If (This.results.failedTests.length=0)
		return $lines
	End if 
	
	$lines.push("")
	$lines.push("=== Failed Tests ===")
	
	var $failedTest : Object
	var $reason : Text
	For each ($failedTest; This.results.failedTests)
		$lines.push("✗ "+This._qualifiedTestName($failedTest))
		For each ($reason; This._describeFailure($failedTest))
			$lines.push("    "+$reason)
		End for each 
		If (This.verboseOutput) && ($failedTest.callChain#Null)
			$lines.combine(This._indentLines(This._formatCallChain($failedTest.callChain); "    "))
		End if 
	End for each 
	
	return $lines
	
Function _buildRuntimeErrorLines() : Collection
	var $lines : Collection
	$lines:=[]
	
	var $failedTest; $error : Object
	var $errorCount : Integer
	For each ($failedTest; This.results.failedTests)
		If ($failedTest.runtimeErrors#Null)
			$errorCount+=$failedTest.runtimeErrors.length
		End if 
	End for each 
	
	If ($errorCount=0)
		return $lines
	End if 
	
	$lines.push("")
	$lines.push("=== Runtime Errors ("+String($errorCount)+") ===")
	
	var $callChain : Collection
	For each ($failedTest; This.results.failedTests)
		If ($failedTest.runtimeErrors#Null)
			For each ($error; $failedTest.runtimeErrors)
				$lines.push("✗ "+This._qualifiedTestName($failedTest))
				$lines.push("    "+This._formatRuntimeError($error))
				$callChain:=This._errorCallChain($error; $failedTest)
				If ($callChain#Null)
					$lines.combine(This._indentLines(This._formatCallChain($callChain); "    "))
				End if 
			End for each 
		End if 
	End for each 
	
	return $lines
	
Function _buildGlobalErrorLines() : Collection
	var $lines : Collection
	$lines:=[]
	If (Not(This.results.hasGlobalErrors))
		return $lines
	End if 
	
	$lines.push("")
	$lines.push("=== Runtime Errors Outside Test Processes ("+String(This.results.globalErrorCount)+") ===")
	
	var $globalError : Object
	var $callChain : Collection
	For each ($globalError; This.results.globalErrors)
		$lines.push(This._formatGlobalErrorForLog($globalError))
		$callChain:=This._errorCallChain($globalError; Null)
		If ($callChain#Null)
			$lines.combine(This._indentLines(This._formatCallChain($callChain); "    "))
		End if 
	End for each 
	
	return $lines
	
Function _buildFinalResultLines() : Collection
	// Failed vs Errors uses the same split as JUnit: errors = tests with a runtime error
	var $errors; $failures; $external : Integer
	$errors:=This._countTestsWithRuntimeErrors()
	$failures:=This.results.failed-$errors
	$external:=Num(This.results.globalErrorCount)
	
	var $lines : Collection
	$lines:=[\
		""; \
		"=== Final Result ==="; \
		"Tests:     "+String(This.results.totalTests); \
		"Passed:    "+String(This.results.passed); \
		"Failed:    "+This._padRight(String($failures); 6)+"(assertion failures)"; \
		"Errors:    "+This._padRight(String($errors); 6)+"(runtime errors in tests)"; \
		"Skipped:   "+String(This.results.skipped); \
		"External:  "+This._padRight(String($external); 6)+"(runtime errors outside test processes)"; \
		"Duration:  "+String(This.results.duration/1000; "#####0.0")+"s"\
		]
	
	If (This.results.failedTests.length>0)
		$lines.push("")
		$lines.push("Failed / errored tests:")
		var $failedTest : Object
		var $hasError : Boolean
		For each ($failedTest; This.results.failedTests)
			$hasError:=($failedTest.runtimeErrors#Null) && ($failedTest.runtimeErrors.length>0)
			$lines.push("  "+($hasError ? "ERROR  " : "FAIL   ")+This._qualifiedTestName($failedTest))
			$lines.push("         "+This._describeFailure($failedTest)[0])
		End for each 
	End if 
	
	$lines.push("")
	If (This.results.failed=0) && ($external=0)
		$lines.push("RESULT: PASS ("+String(This.results.passed)+" passed, "+String(This.results.skipped)+" skipped)")
	Else 
		$lines.push("RESULT: FAIL ("+String($failures)+" failed, "+String($errors)+" error"+(($errors=1) ? "" : "s")+", "+String($external)+" external)")
	End if 
	$lines.push(This._buildVerdictLine($failures; $errors; $external))
	
	return $lines
	
// Last line of the report; people scan for it
Function _buildVerdictLine($failures : Integer; $errors : Integer; $external : Integer) : Text
	If ($failures=0) && ($errors=0) && ($external=0)
		return "All tests passed! 🎉"
	End if 
	
	var $parts : Collection
	$parts:=[]
	If ($failures>0)
		$parts.push("❌ "+String($failures)+" test"+(($failures=1) ? "" : "s")+" failed")
	End if 
	If ($errors>0)
		$parts.push("⚠️ "+String($errors)+" error"+(($errors=1) ? "" : "s"))
	End if 
	If ($external>0)
		$parts.push("⚠️ "+String($external)+" external error"+(($external=1) ? "" : "s"))
	End if 
	return $parts.join(", ")
	
Function _generateJSONReport()
	This:C1470._debugLog("_generateJSONReport: start, totalTests="+String:C10(This:C1470.results.totalTests))
	var $passRate : Real
	var $effectiveTotal : Integer
	$effectiveTotal:=This:C1470.results.totalTests-This:C1470.results.skipped
	If ($effectiveTotal>0)
		$passRate:=(This:C1470.results.passed/$effectiveTotal)*100
	Else 
		$passRate:=0
	End if 
	
	var $jsonReport : Object
	
	var $hasFailures : Boolean
	$hasFailures:=(This:C1470.results.failed>0) || This:C1470.results.hasGlobalErrors
	
	If (This:C1470.verboseOutput)
		// Verbose mode: include all details (original format)
		This:C1470._debugLog("_generateJSONReport: verbose OB Copy")
		$jsonReport:=OB Copy:C1225(This:C1470.results)
		$jsonReport.passRate:=$passRate
		$jsonReport.status:=$hasFailures ? "failure" : "success"
	Else 
		This:C1470._debugLog("_generateJSONReport: terse mode")
		// Terse mode: minimal information
		$jsonReport:=New object:C1471(\
			"tests"; This:C1470.results.totalTests; \
			"passed"; This:C1470.results.passed; \
			"failed"; This:C1470.results.failed; \
			"skipped"; This:C1470.results.skipped; \
			"assertions"; This:C1470.results.assertions; \
			"rate"; Round:C94($passRate; 1); \
			"duration"; This:C1470.results.duration; \
			"globalErrors"; This:C1470.results.globalErrors; \
			"globalErrorCount"; This:C1470.results.globalErrorCount; \
			"hasGlobalErrors"; This:C1470.results.hasGlobalErrors; \
			"status"; $hasFailures ? "fail" : "ok"\
			)
		
		// Include individual test results with assertions and runtime errors
		var $testResults : Collection
		$testResults:=[]
		var $suite : Object
		var $test : Object
		For each ($suite; This:C1470.results.suites)
			For each ($test; $suite.tests)
				var $testEntry : Object
				$testEntry:=New object:C1471(\
					"name"; $test.name; \
					"suite"; $test.suite; \
					"passed"; Not:C34($test.failed) && Not:C34($test.skipped); \
					"failed"; $test.failed; \
					"skipped"; $test.skipped; \
					"duration"; $test.duration; \
					"assertions"; $test.assertions; \
					"assertionCount"; $test.assertionCount\
					)
				
				// Include runtime errors if any
				If ($test.runtimeErrors#Null:C1517) && ($test.runtimeErrors.length>0)
					$testEntry.runtimeErrors:=$test.runtimeErrors
				End if
				
				$testResults.push($testEntry)
			End for each 
		End for each 
		$jsonReport.testResults:=$testResults
		
		// Only include failed tests if there are any
		If (This:C1470.results.failed>0)
			var $failedTests : Collection
			$failedTests:=[]
			var $failedTest : Object
			For each ($failedTest; This:C1470.results.failedTests)
				$failedTests.push(This:C1470._buildTerseFailure($failedTest))
			End for each 
			$jsonReport.failures:=$failedTests
		End if 
		
		// Only include suite summary if there are multiple suites
		If (This:C1470.results.suites.length>1)
			var $suiteSummary : Collection
			$suiteSummary:=[]
			For each ($suite; This:C1470.results.suites)
				$suiteSummary.push(New object:C1471(\
					"name"; $suite.name; \
					"passed"; $suite.passed; \
					"failed"; $suite.failed; \
					"skipped"; $suite.skipped; \
					"assertions"; $suite.assertions\
					))
			End for each 
			$jsonReport.suites:=$suiteSummary
		End if 
	End if 
	
	This:C1470._debugLog("_generateJSONReport: before JSON Stringify")
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($jsonReport; *)
	This:C1470._debugLog("_generateJSONReport: after JSON Stringify, length="+String:C10(Length:C16($jsonString)))
	
	var $outputPath : Text
	$outputPath:=This:C1470.userParams.outputPath || ""
	This:C1470._debugLog("_generateJSONReport: outputPath='"+$outputPath+"'")
	
	If ($outputPath#"")
		This:C1470._writeJSONToFile($jsonString; $outputPath)
	Else 
		This:C1470._logLine($jsonString)
	End if 
	
Function _buildTerseFailure($failedTest : Object) : Object
	var $terseFailure : Object
	$terseFailure:=New object:C1471("test"; $failedTest.name; "suite"; $failedTest.suite)
	If ($failedTest.runtimeErrors#Null:C1517) && ($failedTest.runtimeErrors.length>0)
		var $firstError : Object
		$firstError:=$failedTest.runtimeErrors[0]
		$terseFailure.error:=This:C1470._formatRuntimeError($firstError)
		$terseFailure.errorCode:=$firstError.code
		$terseFailure.errorMethod:=$firstError.text
		$terseFailure.errorLine:=$firstError.line
	Else 
		If ($failedTest.logMessages#Null:C1517) && ($failedTest.logMessages.length>0)
			$terseFailure.reason:=$failedTest.logMessages[0]
		End if 
	End if 
	
	// Terse JSON: callChain when verbose or callchain=true (see _determineOutputFormat)
	If (This:C1470.callChainOutput) && ($failedTest.callChain#Null:C1517)
		$terseFailure.callChain:=$failedTest.callChain
	End if 
	return $terseFailure
	
Function _writeJSONToFile($jsonContent : Text; $outputPath : Text)
	var $jsonFile : 4D:C1709.File
	$jsonFile:=This:C1470._resolveOutputFile($outputPath)
	
	var $outputFolder : 4D:C1709.Folder
	$outputFolder:=$jsonFile.parent
	If (Not:C34($outputFolder.exists))
		$outputFolder.create()
	End if 
	
	$jsonFile.setText($jsonContent; "UTF-8")
	
	This:C1470._logLine("JSON results written to: "+$jsonFile.platformPath)
	
Function _generateJUnitXMLReport()
	var $params : Object
	$params:=This:C1470._parseUserParams()
	
	// Determine output path - default to test-results/junit.xml in project root
	var $outputPath : Text
	$outputPath:=($params.outputPath#Null:C1517) ? $params.outputPath : "test-results/junit.xml"
	
	// Build JUnit XML content
	var $xmlContent : Text
	$xmlContent:=This:C1470._buildJUnitXML()
	
	// Write XML to file
	This:C1470._writeJUnitXMLToFile($xmlContent; $outputPath)
	
Function _buildJUnitXML() : Text
	var $xml : Text
	var $totalTime : Real
	$totalTime:=This:C1470.results.duration/1000  // Convert ms to seconds
	
	// JUnit testsuites/@errors counts only TEST errors (failed tests with a runtime
	// error). External (non-test) runtime errors live in <system-err>; including
	// them here would inflate @errors and drive @failures negative.
	var $totalErrors; $totalFailures : Integer
	$totalErrors:=This:C1470._countTestsWithRuntimeErrors()
	$totalFailures:=This:C1470.results.failed-$totalErrors  // assertion failures
	
	// XML header and root testsuites element
	$xml:="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n"
	$xml:=$xml+"<testsuites name=\"4D Test Results\""
	$xml:=$xml+" tests=\""+String:C10(This:C1470.results.totalTests)+"\""
	$xml:=$xml+" failures=\""+String:C10($totalFailures)+"\""
	$xml:=$xml+" errors=\""+String:C10($totalErrors)+"\""
	$xml:=$xml+" skipped=\""+String:C10(This:C1470.results.skipped)+"\""
	$xml:=$xml+" time=\""+String:C10($totalTime; "##0.000")+"\""
	$xml:=$xml+" timestamp=\""+This:C1470._formatTimestamp(This:C1470.results.startTime)+"\">\r\n"
	
	// Build testsuite elements
	var $suite : Object
	For each ($suite; This:C1470.results.suites)
		$xml:=$xml+This:C1470._buildTestSuiteXML($suite)
	End for each 
	
	If (This:C1470.results.hasGlobalErrors)
		$xml:=$xml+This:C1470._buildGlobalErrorsSystemErr()
	End if 
	
	$xml:=$xml+"</testsuites>\r\n"
	
	return $xml
	
Function _buildTestSuiteXML($suite : Object) : Text
	var $xml : Text
	var $suiteTotalTime : Real
	
	// Calculate total time for this suite
	$suiteTotalTime:=0
	var $test : Object
	For each ($test; $suite.tests)
		$suiteTotalTime:=$suiteTotalTime+($test.duration/1000)  // Convert ms to seconds
	End for each 
	
	// Calculate errors and failures for this suite
	var $suiteErrors; $suiteFailures; $suiteSkipped : Integer
	$suiteErrors:=This:C1470._countSuiteTestsWithRuntimeErrors($suite)
	$suiteFailures:=$suite.failed-$suiteErrors
	$suiteSkipped:=Num:C11($suite.skipped)
	
	// Build testsuite element
	$xml:="  <testsuite name=\""+This:C1470._escapeXMLAttribute($suite.name)+"\""
	$xml:=$xml+" tests=\""+String:C10($suite.tests.length)+"\""
	$xml:=$xml+" failures=\""+String:C10($suiteFailures)+"\""
	$xml:=$xml+" errors=\""+String:C10($suiteErrors)+"\""
	$xml:=$xml+" skipped=\""+String:C10($suiteSkipped)+"\""
	$xml:=$xml+" time=\""+String:C10($suiteTotalTime; "##0.000")+"\""
	$xml:=$xml+">\r\n"
	
	// Build testcase elements
	For each ($test; $suite.tests)
		$xml:=$xml+This:C1470._buildTestCaseXML($test)
	End for each 
	
	$xml:=$xml+"  </testsuite>\r\n"
	
	return $xml
	
Function _buildTestCaseXML($test : Object) : Text
	var $xml : Text
	var $testTime : Real
	$testTime:=$test.duration/1000  // Convert ms to seconds
	
	// Build basic testcase element
	$xml:="    <testcase"
	$xml:=$xml+" classname=\""+This:C1470._escapeXMLAttribute($test.suite)+"\""
	$xml:=$xml+" name=\""+This:C1470._escapeXMLAttribute($test.name)+"\""
	$xml:=$xml+" file=\"testing/Project/Sources/Classes/"+This:C1470._escapeXMLAttribute($test.suite)+".4dm\""
	$xml:=$xml+" time=\""+String:C10($testTime; "##0.000")+"\""
	
	Case of 
		: ($test.failed)
			$xml:=$xml+">\r\n"
			$xml:=$xml+This:C1470._buildFailureXML($test)
			$xml:=$xml+"    </testcase>\r\n"
		: (Bool:C1537($test.skipped))
			// JUnit consumers (Jenkins, JUnitXML, etc.) require a <skipped/> child
			// to recognize a testcase as skipped vs. passed.
			$xml:=$xml+">\r\n"
			$xml:=$xml+"      <skipped/>\r\n"
			$xml:=$xml+"    </testcase>\r\n"
		Else 
			$xml:=$xml+" />\r\n"
	End case 
	
	return $xml
	
Function _buildFailureXML($test : Object) : Text
	var $elementType; $errorType; $message : Text
	var $hasRuntimeErrors : Boolean
	var $reasons; $details; $callChain : Collection
	var $error : Object
	
	$hasRuntimeErrors:=($test.runtimeErrors#Null) && ($test.runtimeErrors.length>0)
	$reasons:=This._describeFailure($test)
	$details:=$reasons.copy()
	
	If ($hasRuntimeErrors)
		$elementType:="error"
		$errorType:="RuntimeError"
		$message:=This._runtimeErrorSummary($test.runtimeErrors[0])
		If ($test.runtimeErrors.length>1)
			$message:=$message+" (+"+String($test.runtimeErrors.length-1)+" more)"
		End if 
	Else 
		$elementType:="failure"
		$errorType:="AssertionFailure"
		$message:=$reasons[0]
		
		// Log messages that aren't already the text of a failed assertion
		var $assertionMessages; $extraLogs : Collection
		$assertionMessages:=[]
		var $assertion : Object
		If ($test.assertions#Null)
			For each ($assertion; $test.assertions)
				If (Not(Bool($assertion.passed)))
					$assertionMessages.push(This._errorTextField($assertion; "message"))
				End if 
			End for each 
		End if 
		$extraLogs:=[]
		var $logMessage : Text
		If ($test.logMessages#Null)
			For each ($logMessage; $test.logMessages)
				If ($assertionMessages.indexOf($logMessage)<0) && ($reasons.indexOf($logMessage)<0)
					$extraLogs.push("  "+$logMessage)
				End if 
			End for each 
		End if 
		If ($extraLogs.length>0)
			$details.push("")
			$details.push("Log:")
			$details.combine($extraLogs)
		End if 
	End if 
	
	$details.push("")
	$details.push("Test: "+This._qualifiedTestName($test))
	
	var $addedChain : Boolean
	If ($hasRuntimeErrors)
		For each ($error; $test.runtimeErrors)
			$callChain:=This._errorCallChain($error; Null)
			If ($callChain#Null)
				$details.push("")
				If ($test.runtimeErrors.length>1)
					$details.push("Error "+This._runtimeErrorSummary($error)+":")
				End if 
				$details.combine(This._indentLines(This._formatCallChain($callChain); ""))
				$addedChain:=True
			End if 
		End for each 
	End if 
	If (Not($addedChain)) && (Value type($test.callChain)=Is collection)
		$details.push("")
		$details.combine(This._indentLines(This._formatCallChain($test.callChain); ""))
	End if 
	
	var $xml : Text
	$xml:="      <"+$elementType+" type=\""+$errorType+"\" message=\""+This._escapeXMLAttribute($message)+"\">"
	$xml:=$xml+"<![CDATA[\n"+This._escapeCDATA($details.join("\n"))+"\n]]>"
	$xml:=$xml+"</"+$elementType+">\r\n"
	
	return $xml
	
Function _escapeCDATA($text : Text) : Text
	return Replace string($text; "]]>"; "]]]]><![CDATA[>")
	
Function _buildGlobalErrorsSystemErr() : Text
	var $xml : Text
	
	$xml:="  <system-err><![CDATA[\n"
	$xml:=$xml+"External runtime errors detected: "+String:C10(This:C1470.results.globalErrorCount)+"\n"
	
	var $error : Object
	For each ($error; This:C1470.results.globalErrors)
		$xml:=$xml+This:C1470._formatGlobalErrorForLog($error)+"\n"
	End for each 
	
	$xml:=$xml+"]]></system-err>\r\n"
	
	return $xml
	
Function _writeJUnitXMLToFile($xmlContent : Text; $outputPath : Text)
	var $xmlFile : 4D:C1709.File
	$xmlFile:=This:C1470._resolveOutputFile($outputPath)
	
	var $outputFolder : 4D:C1709.Folder
	$outputFolder:=$xmlFile.parent
	If (Not:C34($outputFolder.exists))
		$outputFolder.create()
	End if 
	
	$xmlFile.setText($xmlContent; "UTF-8")
	
	// Log file location for CI visibility
	This:C1470._logLine("JUnit XML written to: "+$xmlFile.platformPath)
	
Function _escapeXMLAttribute($text : Text) : Text
	var $escaped : Text
	$escaped:=Replace string:C233($text; "&"; "&amp;")
	$escaped:=Replace string:C233($escaped; "<"; "&lt;")
	$escaped:=Replace string:C233($escaped; ">"; "&gt;")
	$escaped:=Replace string:C233($escaped; "\""; "&quot;")
	$escaped:=Replace string:C233($escaped; "'"; "&apos;")
	return $escaped
	
Function _resolveOutputFile($outputPath : Text) : 4D:C1709.File
	If (($outputPath[[1]]="/") || (Position:C15(":"; $outputPath)>0))
		return File:C1566($outputPath; fk posix path:K87:1)
	End if 
	
	var $pathParts : Collection
	$pathParts:=Split string:C1554($outputPath; "/")
	
	var $baseFolder : 4D:C1709.Folder
	If ($pathParts.length>1)
		var $folderPath : Text
		$folderPath:=$pathParts.slice(0; $pathParts.length-1).join("/")
		$baseFolder:=Folder:C1567(fk database folder:K87:14; *).folder($folderPath)
	Else 
		$baseFolder:=Folder:C1567(fk database folder:K87:14; *)
	End if 
	
	return $baseFolder.file($pathParts[$pathParts.length-1])
	
Function _formatTimestamp($milliseconds : Integer) : Text
	// ISO 8601 local timestamp: YYYY-MM-DDTHH:MM:SS
	// Note: $milliseconds is a Milliseconds counter (relative to app start), so we
	// can't reconstruct a wall-clock timestamp from it. Use Current date/time.
	// String(Current date; ISO date GMT) returns "YYYY-MM-DDT00:00:00Z"; take only
	// the date prefix and append the local time. (No "Z" — these are local values.)
	var $timestamp : Text
	$timestamp:=Substring:C12(String:C10(Current date:C33; ISO date GMT:K1:10); 1; 10)+"T"+String:C10(Current time:C178; HH MM SS:K7:1)
	return $timestamp
	
Function getResults() : Object
	return This:C1470.results
	
Function _determineOutputFormat()
	var $params : Object
	$params:=This:C1470._effectiveParams()
	
	If ($params.format="json")
		This:C1470.outputFormat:="json"
	Else 
		If ($params.format="junit") || ($params.format="xml")
			This:C1470.outputFormat:="junit"
		Else 
			This:C1470.outputFormat:="human"
		End if 
	End if 
	
	// Terse JSON: call chains only when verbose or explicit callchain=true
	This:C1470.verboseOutput:=($params.verbose="true")
	This:C1470.callChainOutput:=This:C1470.verboseOutput || ($params.callchain="true")
	
	This:C1470.consoleReport:=(This:C1470.outputFormat="human") || (This:C1470.outputFormat="junit")
	This:C1470.quietOutput:=($params.quiet="true")
	This:C1470.debugOutput:=($params.debug="true")
	
Function _parseTestPatterns()
	var $params : Object
	$params:=This:C1470._parseUserParams()
	This:C1470.testPatterns:=[]
	
	var $testParam : Text
	$testParam:=$params.test || ""
	
	// Split by commas for multiple patterns
	If ($testParam#"")
		var $patterns : Collection
		$patterns:=Split string:C1554($testParam; ",")
		var $pattern : Text
		For each ($pattern; $patterns)
			$pattern:=Replace string:C233($pattern; " "; "")  // Remove spaces
			If ($pattern#"")
				This:C1470.testPatterns.push($pattern)
			End if 
		End for each 
	End if 
	
Function _shouldIncludeTestSuite($testSuite : cs:C1710._TestSuite) : Boolean
	// If no patterns specified, include all tests
	If (This:C1470.testPatterns.length=0)
		return True:C214
	End if 
	
	var $suiteName : Text
	$suiteName:=$testSuite.class.name
	
	// Check each pattern
	var $pattern : Text
	For each ($pattern; This:C1470.testPatterns)
		// Check if pattern matches suite name
		If (This:C1470._matchesPattern($suiteName; $pattern))
			return True:C214
		End if 
		
		// Check if pattern matches any test method in this suite
		If (This:C1470._patternMatchesAnyTestInSuite($testSuite; $pattern))
			return True:C214
		End if 
	End for each 
	
	return False:C215
	
Function _patternMatchesAnyTestInSuite($testSuite : cs:C1710._TestSuite; $pattern : Text) : Boolean
	var $testFunction : cs:C1710._TestFunction
	For each ($testFunction; $testSuite.testFunctions)
		var $fullTestName : Text
		$fullTestName:=$testSuite.class.name+"."+$testFunction.functionName
		
		If (This:C1470._matchesPattern($fullTestName; $pattern)) || (This:C1470._matchesPattern($testFunction.functionName; $pattern))
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
	
Function _parseUserParams() : Object
	var $userParam : Text
	$userParam:=This:C1470._getUserParam()
	
	return This:C1470._parseParamString($userParam)
	
Function _getUserParam() : Text
	// Extracted method to make testing easier - can be mocked
	var $userParam : Text
	var $real : Real
	$real:=Get database parameter:C643(User param value:K37:94; $userParam)
	return $userParam
	
Function _parseParamString($userParam : Text) : Object
	var $params : Object
	$params:=New object:C1471
	
	// Parse space-separated key=value pairs
	// Format: "format=json test=ExampleTest" or "format:json test:ExampleTest"
	var $parts : Collection
	$parts:=Split string:C1554($userParam; " ")
	
	var $part : Text
	For each ($part; $parts)
		$part:=Replace string:C233($part; " "; "")  // Remove any extra spaces
		If ($part#"")
			var $keyValue : Collection
			
			// Try = separator first
			If (Position:C15("="; $part)>0)
				$keyValue:=Split string:C1554($part; "=")
				If ($keyValue.length=2)
					$params[$keyValue[0]]:=$keyValue[1]
				End if 
				// Try : separator as alternative
			Else 
				If (Position:C15(":"; $part)>0)
					$keyValue:=Split string:C1554($part; ":")
					If ($keyValue.length=2)
						$params[$keyValue[0]]:=$keyValue[1]
					End if 
				End if 
			End if 
		End if 
	End for each 
	
	return $params
	
Function _parseTagFilters()
	// Parse tag filters from user parameters
	var $params : Object
	$params:=This:C1470._parseUserParams()
	
	This:C1470.includeTags:=This:C1470._parseTagList($params.tags)
	This:C1470.excludeTags:=This:C1470._parseTagList($params.excludeTags)
	This:C1470.requireAllTags:=This:C1470._parseTagList($params.requireTags)
	
Function _parseTagList($tagString : Text) : Collection
	// Parse comma-separated tag list
	var $tags : Collection
	$tags:=[]
	
	If ($tagString#Null:C1517) && ($tagString#"")
		var $tagParts : Collection
		$tagParts:=Split string:C1554($tagString; ",")
		var $tag : Text
		For each ($tag; $tagParts)
			$tag:=Replace string:C233($tag; " "; "")  // Remove spaces
			If ($tag#"")
				$tags.push($tag)
			End if 
		End for each 
	End if 
	
	return $tags
	
Function _countTestsWithRuntimeErrors() : Integer
	// Count total tests that have runtime errors (not assertion failures)
	var $errorCount : Integer
	$errorCount:=0
	
	var $suite : Object
	For each ($suite; This:C1470.results.suites)
		$errorCount:=$errorCount+This:C1470._countSuiteTestsWithRuntimeErrors($suite)
	End for each 
	
	return $errorCount
	
Function _countSuiteTestsWithRuntimeErrors($suite : Object) : Integer
	// Count tests in a specific suite that have runtime errors
	var $errorCount : Integer
	$errorCount:=0
	
	var $test : Object
	For each ($test; $suite.tests)
		If ($test.runtimeErrors#Null:C1517) && ($test.runtimeErrors.length>0)
			$errorCount:=$errorCount+1
		End if 
	End for each 
	
	return $errorCount
	
Function _shouldIncludeTestByTags($testFunction : cs:C1710._TestFunction) : Boolean
	// Apply tag filtering logic to determine if test should be included
	
	// If no tag filters specified, include all tests
	If (This:C1470.includeTags.length=0) && (This:C1470.excludeTags.length=0) && (This:C1470.requireAllTags.length=0)
		return True:C214
	End if 
	
	// Check exclude tags first (highest priority)
	If (This:C1470.excludeTags.length>0)
		If ($testFunction.hasTags(This:C1470.excludeTags))
			return False:C215
		End if 
	End if 
	
	// Check require all tags (must have ALL specified tags)
	If (This:C1470.requireAllTags.length>0)
		If (Not:C34($testFunction.hasAllTags(This:C1470.requireAllTags)))
			return False:C215
		End if 
	End if 
	
	// Check include tags (must have at least ONE of the specified tags)
	If (This:C1470.includeTags.length>0)
		return $testFunction.hasTags(This:C1470.includeTags)
	End if 
	
	// If we have exclude or require filters but no include filters, default to true
	return True:C214
	
Function _formatCallChain($callChain : Collection) : Text
	// Format the call chain into a readable string for debugging
	var $result : Text
	var $i : Integer
	var $callInfo : Object
	
	$result:=""
	
	If ($callChain#Null:C1517)
		$result:="Call Stack:"
		
		For ($i; 0; $callChain.length-1)
			$callInfo:=$callChain[$i]
			$result:=$result+"\r\n  "+String:C10($i+1)+". "
			
			If ($callInfo.name#Null:C1517)
				$result:=$result+$callInfo.name
			Else 
				$result:=$result+"<unnamed>"
			End if 
			
			If ($callInfo.type#Null:C1517)
				$result:=$result+" ("+$callInfo.type+")"
			End if 
			
			If ($callInfo.line#Null:C1517)
				$result:=$result+" at line "+String:C10($callInfo.line)
			End if 
			
			If ($callInfo.database#Null:C1517)
				$result:=$result+" in "+$callInfo.database
			End if 
		End for 
	End if 
	
	return $result