property classStore : 4D:C1709.Object  // Class store from the calling project
property hostStorage : 4D:C1709.Object  // Host project's Storage for trigger control
property testSuites : Collection  // Collection of cs._TestSuite
property results : Object  // Test results summary
property outputFormat : Text  // "human", "json", "junit"
property verboseOutput : Boolean  // Whether to include detailed information
property testPatterns : Collection  // Collection of test patterns to match
property includeTags : Collection  // Tags to include (OR logic)
property excludeTags : Collection  // Tags to exclude
property requireAllTags : Collection  // Tags that must all be present (AND logic)
property userParams : Object  // User parameters passed to the runner
property disableTriggersByDefault : Boolean  // Whether triggers are disabled by default
property coverageEnabled : Boolean  // Whether code coverage is enabled
property coverageTracker : cs:C1710.CoverageTracker  // Coverage data tracker
property coverageInstrumenter : cs:C1710.CodeInstrumenter  // Code instrumenter
property coverageReporter : cs:C1710.CoverageReporter  // Coverage reporter
property coverageMethods : Collection  // Methods to track for coverage

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
	This:C1470._initializeCoverage()
	
Function run()
	This:C1470._initializeTriggerControl()
	This:C1470._prepareErrorHandlingStorage()
	var $handlerState : Object
	$handlerState:=This:C1470._installErrorHandler()
	
	// Setup coverage if enabled
	If (This:C1470.coverageEnabled)
		This:C1470._setupCoverage()
	End if 
	
	This:C1470._runInternal()
	This:C1470._captureGlobalErrors()
	
	// Teardown coverage if enabled
	If (This:C1470.coverageEnabled)
		This:C1470._teardownCoverage()
	End if 
	
	This:C1470._restoreErrorHandler($handlerState)
	
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
	
Function _runInternal()
	This:C1470._prepareSuites()
	This:C1470._runSuitesSequentially()
	
Function _prepareSuites()
	This:C1470._initializeResults()
	This:C1470.testSuites:=[]
	This:C1470.discoverTests()
	
Function _runSuitesSequentially()
	This:C1470.results.startTime:=Milliseconds:C459
	
	If (This:C1470.outputFormat="human")
		This:C1470._logHeader()
	End if 
	
	var $testSuite : cs:C1710._TestSuite
	For each ($testSuite; This:C1470.testSuites)
		$testSuite.run()
		This:C1470._collectSuiteResults($testSuite)
	End for each 
	
	This:C1470.results.endTime:=Milliseconds:C459
	This:C1470.results.duration:=This:C1470.results.endTime-This:C1470.results.startTime
	This:C1470._generateReport()
	
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
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "=== 4D Unit Testing Framework ===\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Running tests...\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	
Function _collectSuiteResults($testSuite : cs:C1710._TestSuite)
	// Skip suites with no tests
	If ($testSuite.testFunctions.length=0)
		return 
	End if 
	
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
			If (This:C1470.outputFormat="human")
				LOG EVENT:C667(Into system standard outputs:K38:9; "  - "+$testResult.name+" (skipped)\r\n"; Information message:K38:1)
			End if 
		Else 
			If ($testResult.passed)
				This:C1470.results.passed+=1
				$suiteResult.passed+=1
				If (This:C1470.outputFormat="human")
					LOG EVENT:C667(Into system standard outputs:K38:9; "  ✓ "+$testResult.name+" ("+String:C10($testResult.duration)+"ms)\r\n"; Information message:K38:1)
				End if 
			Else 
				This:C1470.results.failed+=1
				$suiteResult.failed+=1
				This:C1470.results.failedTests.push($testResult)
				If (This:C1470.outputFormat="human")
					var $errorDetails : Text
					$errorDetails:=""
					If ($testResult.runtimeErrors.length>0)
						$errorDetails:=" [Runtime Error: "+$testResult.runtimeErrors[0].text+"]"
					Else 
						If ($testResult.logMessages.length>0)
							$errorDetails:=" ["+$testResult.logMessages[0]+"]"
						End if 
					End if 
					
					// Add call chain information if available
					If ($testResult.callChain#Null:C1517)
						$errorDetails:=$errorDetails+"\r\n"+This:C1470._formatCallChain($testResult.callChain)
					End if 
					LOG EVENT:C667(Into system standard outputs:K38:9; "  ✗ "+$testResult.name+" ("+String:C10($testResult.duration)+"ms)"+$errorDetails+"\r\n"; Error message:K38:3)
				End if 
			End if 
		End if 
		
		$suiteResult.tests.push($testResult)
		This:C1470.results.assertions+=($testResult.assertionCount)
		$suiteResult.assertions+=($testResult.assertionCount)
	End for each 
	
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
	
	return $globalErrors
	
Function _formatGlobalErrorForLog($error : Object) : Text
	var $codeText : Text
	var $processText : Text
	var $methodText : Text
	var $lineText : Text
	var $formulaText : Text
	var $message : Text
	
	$codeText:=($error.code#Null:C1517) ? String:C10($error.code) : "?"
	$processText:=($error.processNumber#Null:C1517) ? String:C10($error.processNumber) : "?"
	$methodText:=$error.text || "Unknown location"
	
	If ($error.line#Null:C1517)
		$lineText:=" line "+String:C10($error.line)
	Else 
		$lineText:=""
	End if 
	
	$formulaText:=$error.method || ""
	
	$message:="- ["+$codeText+"] Process "+$processText+": "+$methodText+$lineText
	
	If ($formulaText#"")
		$message:=$message+"\r\n      "+$formulaText
	End if 
	
	return $message
	
Function _generateReport()
	If (This:C1470.outputFormat="json")
		This:C1470._generateJSONReport()
	Else 
		If (This:C1470.outputFormat="junit")
			This:C1470._generateJUnitXMLReport()
		Else 
			If (This:C1470.outputFormat#"none")
				This:C1470._generateHumanReport()
			End if 
		End if 
	End if 
	
Function _generateHumanReport()
	var $passRate : Real
	var $effectiveTotal : Integer
	$effectiveTotal:=This:C1470.results.totalTests-This:C1470.results.skipped
	If ($effectiveTotal>0)
		$passRate:=(This:C1470.results.passed/$effectiveTotal)*100
	Else 
		$passRate:=0
	End if 
	
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "=== Test Results Summary ===\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Total Tests: "+String:C10(This:C1470.results.totalTests)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Passed: "+String:C10(This:C1470.results.passed)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Failed: "+String:C10(This:C1470.results.failed)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Skipped: "+String:C10(This:C1470.results.skipped)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Assertions: "+String:C10(This:C1470.results.assertions)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Pass Rate: "+String:C10($passRate; "##0.0")+"%\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Duration: "+String:C10(This:C1470.results.duration)+"ms\r\n"; Information message:K38:1)
	
	var $externalMessageType : Integer
	$externalMessageType:=Choose:C955(This:C1470.results.globalErrorCount>0; Error message:K38:3; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "External Errors: "+String:C10(This:C1470.results.globalErrorCount)+"\r\n"; $externalMessageType)
	
	If (This:C1470.results.failed>0)
		LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
		LOG EVENT:C667(Into system standard outputs:K38:9; "=== Failed Tests ===\r\n"; Error message:K38:3)
		
		var $failedTest : Object
		For each ($failedTest; This:C1470.results.failedTests)
			var $failureReason : Text
			$failureReason:=""
			
			If ($failedTest.runtimeErrors.length>0)
				$failureReason:=" (Runtime Error: "+$failedTest.runtimeErrors[0].text+")"
			Else 
				If ($failedTest.logMessages.length>0)
					$failureReason:=" ("+$failedTest.logMessages[0]+")"
				End if 
			End if 
			
			LOG EVENT:C667(Into system standard outputs:K38:9; "- "+$failedTest.name+$failureReason+"\r\n"; Error message:K38:3)
			
			// Add detailed call chain if available
			If ($failedTest.callChain#Null:C1517)
				LOG EVENT:C667(Into system standard outputs:K38:9; This:C1470._formatCallChain($failedTest.callChain)+"\r\n"; Error message:K38:3)
			End if 
		End for each 
	End if 
	
	If (This:C1470.results.hasGlobalErrors)
		LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
		LOG EVENT:C667(Into system standard outputs:K38:9; "=== Runtime Errors Outside Test Processes ===\r\n"; Error message:K38:3)
		
		var $globalError : Object
		For each ($globalError; This:C1470.results.globalErrors)
			LOG EVENT:C667(Into system standard outputs:K38:9; This:C1470._formatGlobalErrorForLog($globalError)+"\r\n"; Error message:K38:3)
		End for each 
	End if 
	
	This:C1470._logFooter()
	
Function _generateJSONReport()
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
		$jsonReport:=OB Copy:C1225(This:C1470.results)
		$jsonReport.passRate:=$passRate
		$jsonReport.status:=$hasFailures ? "failure" : "success"
	Else 
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
		
		// Include individual test results with assertions
		var $testResults : Collection
		$testResults:=[]
		var $suite : Object
		var $test : Object
		For each ($suite; This:C1470.results.suites)
			For each ($test; $suite.tests)
				$testResults.push(New object:C1471(\
					"name"; $test.name; \
					"suite"; $test.suite; \
					"passed"; Not:C34($test.failed) && Not:C34($test.skipped); \
					"failed"; $test.failed; \
					"skipped"; $test.skipped; \
					"duration"; $test.duration; \
					"assertions"; $test.assertions; \
					"assertionCount"; $test.assertionCount\
					))
			End for each 
		End for each 
		$jsonReport.testResults:=$testResults
		
		// Only include failed tests if there are any
		If (This:C1470.results.failed>0)
			var $failedTests : Collection
			$failedTests:=[]
			var $failedTest : Object
			For each ($failedTest; This:C1470.results.failedTests)
				var $terseFailure : Object
				$terseFailure:=New object:C1471("test"; $failedTest.name; "suite"; $failedTest.suite)
				// Only include error details if they exist and are different
				If ($failedTest.runtimeErrors.length>0)
					$terseFailure.error:=$failedTest.runtimeErrors[0].text
				Else 
					If ($failedTest.logMessages.length>0)
						$terseFailure.reason:=$failedTest.logMessages[0]
					End if 
				End if 
				
				// Include call chain in verbose JSON output
				If (This:C1470.verboseOutput) && ($failedTest.callChain#Null:C1517)
					$terseFailure.callChain:=$failedTest.callChain
				End if 
				$failedTests.push($terseFailure)
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
	
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($jsonReport; *)
	
	LOG EVENT:C667(Into system standard outputs:K38:9; $jsonString; Information message:K38:1)
	
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
	
	// Calculate errors and failures separately
	var $totalErrors; $totalFailures : Integer
	var $globalErrorCount : Integer
	$totalErrors:=This:C1470._countTestsWithRuntimeErrors()
	$globalErrorCount:=This:C1470.results.globalErrorCount
	$totalErrors:=$totalErrors+$globalErrorCount
	$totalFailures:=This:C1470.results.failed-$totalErrors  // Failures are failed tests without runtime errors
	
	// XML header and root testsuites element
	$xml:="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n"
	$xml:=$xml+"<testsuites name=\"4D Test Results\""
	$xml:=$xml+" tests=\""+String:C10(This:C1470.results.totalTests)+"\""
	$xml:=$xml+" failures=\""+String:C10($totalFailures)+"\""
	$xml:=$xml+" errors=\""+String:C10($totalErrors)+"\""
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
	var $suiteErrors; $suiteFailures : Integer
	$suiteErrors:=This:C1470._countSuiteTestsWithRuntimeErrors($suite)
	$suiteFailures:=$suite.failed-$suiteErrors
	
	// Build testsuite element
	$xml:="  <testsuite name=\""+This:C1470._escapeXMLAttribute($suite.name)+"\""
	$xml:=$xml+" tests=\""+String:C10($suite.tests.length)+"\""
	$xml:=$xml+" failures=\""+String:C10($suiteFailures)+"\""
	$xml:=$xml+" errors=\""+String:C10($suiteErrors)+"\""
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
	
	// If test failed, add failure element
	If ($test.failed)
		$xml:=$xml+">\r\n"
		$xml:=$xml+This:C1470._buildFailureXML($test)
		$xml:=$xml+"    </testcase>\r\n"
	Else 
		$xml:=$xml+" />\r\n"
	End if 
	
	return $xml
	
Function _buildFailureXML($test : Object) : Text
	var $xml : Text
	var $failureMessage : Text
	var $failureDetails : Text
	var $elementType : Text
	
	// Extract failure message and details, determine element type
	If ($test.runtimeErrors.length>0)
		$failureMessage:=($test.runtimeErrors[0].text#Null:C1517) ? $test.runtimeErrors[0].text : "Runtime Error"
		$failureDetails:=$failureMessage
		$elementType:="error"
	Else 
		If ($test.logMessages.length>0)
			$failureMessage:=$test.logMessages[0]
			$failureDetails:=$test.logMessages.join("\n")
		Else 
			$failureMessage:="Test failed"
			$failureDetails:="Test failed without specific error message"
		End if 
		$elementType:="failure"
	End if 
	
	$xml:="      <"+$elementType+" message=\""+This:C1470._escapeXMLAttribute($failureMessage)+"\">"
	$xml:=$xml+"<![CDATA[\n"+$failureDetails+"\nLocation: "+$test.suite+"."+$test.name
	
	// Include call chain in JUnit XML if available
	If ($test.callChain#Null:C1517)
		$xml:=$xml+"\n\n"+This:C1470._formatCallChain($test.callChain)
	End if 
	
	$xml:=$xml+"\n]]>"
	$xml:=$xml+"</"+$elementType+">\r\n"
	
	return $xml
	
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
	// Parse the path to determine folder and filename
	var $pathParts : Collection
	$pathParts:=Split string:C1554($outputPath; "/")
	
	// Build output folder path
	var $outputFolder : 4D:C1709.Folder
	If ($pathParts.length>1)
		var $folderPath : Text
		$folderPath:=$pathParts.slice(0; $pathParts.length-1).join("/")
		$outputFolder:=Folder:C1567(fk database folder:K87:14; *).folder($folderPath)
	Else 
		$outputFolder:=Folder:C1567(fk database folder:K87:14; *)
	End if 
	
	// Create output folder if it doesn't exist
	If (Not:C34($outputFolder.exists))
		$outputFolder.create()
	End if 
	
	// Get filename
	var $filename : Text
	$filename:=$pathParts[$pathParts.length-1]
	
	// Create and write XML file
	var $xmlFile : 4D:C1709.File
	$xmlFile:=$outputFolder.file($filename)
	$xmlFile.setText($xmlContent; "UTF-8")
	
	// Log file location for CI visibility
	LOG EVENT:C667(Into system standard outputs:K38:9; "JUnit XML written to: "+$xmlFile.platformPath+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; \
		"Summary: "+String:C10(This:C1470.results.totalTests)+" tests, "+String:C10(This:C1470.results.passed)+" passed, "+String:C10(This:C1470.results.failed)+" failed"+Char:C90(13)+Char:C90(10); \
		Information message:K38:1)
	
Function _escapeXMLAttribute($text : Text) : Text
	var $escaped : Text
	$escaped:=Replace string:C233($text; "&"; "&amp;")
	$escaped:=Replace string:C233($escaped; "<"; "&lt;")
	$escaped:=Replace string:C233($escaped; ">"; "&gt;")
	$escaped:=Replace string:C233($escaped; "\""; "&quot;")
	$escaped:=Replace string:C233($escaped; "'"; "&apos;")
	return $escaped
	
Function _formatTimestamp($milliseconds : Integer) : Text
	// Convert milliseconds to ISO 8601 timestamp
	var $date : Date
	var $time : Time
	var $timestamp : Text
	
	// For now, use current timestamp - could be enhanced to use actual start time
	$timestamp:=String:C10(Current date:C33; ISO date GMT:K1:10)+"T"+String:C10(Current time:C178; HH MM SS:K7:1)
	return $timestamp
	
Function _logFooter()
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	If ((This:C1470.results.failed=0) && Not:C34(This:C1470.results.hasGlobalErrors))
		LOG EVENT:C667(Into system standard outputs:K38:9; "All tests passed! 🎉\r\n"; Information message:K38:1)
	Else 
		var $summaryMessage : Text
		$summaryMessage:=""
		
		If (This:C1470.results.failed>0)
			$summaryMessage:=String:C10(This:C1470.results.failed)+" test(s) failed"
		End if 
		
		If (This:C1470.results.hasGlobalErrors)
			If ($summaryMessage#"")
				$summaryMessage:=$summaryMessage+"; "
			End if 
			$summaryMessage:=$summaryMessage+String:C10(This:C1470.results.globalErrorCount)+" external runtime error(s)"
		End if 
		
		LOG EVENT:C667(Into system standard outputs:K38:9; $summaryMessage+"\r\n"; Error message:K38:3)
	End if 
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	
Function getResults() : Object
	return This:C1470.results
	
Function _determineOutputFormat()
	var $params : Object
	$params:=This:C1470._parseUserParams()
	
	If ($params.format="json")
		This:C1470.outputFormat:="json"
	Else 
		If ($params.format="junit") || ($params.format="xml")
			This:C1470.outputFormat:="junit"
		Else 
			This:C1470.outputFormat:="human"
		End if 
	End if 
	
	// Check for verbose flag
	This:C1470.verboseOutput:=($params.verbose="true")
	
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
		If ($test.runtimeErrors.length>0)
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
	
// ===== Coverage Support =====

Function _initializeCoverage()
	// Initialize coverage tracking based on user parameters
	This:C1470.coverageEnabled:=False:C215
	This:C1470.coverageMethods:=[]
	
	var $coverageParam : Text
	$coverageParam:=This:C1470.userParams.coverage || ""
	
	If ($coverageParam="true") || ($coverageParam="enabled")
		This:C1470.coverageEnabled:=True:C214
		
		// Initialize coverage components
		This:C1470.coverageTracker:=cs:C1710.CoverageTracker.new()
		This:C1470.coverageInstrumenter:=cs:C1710.CodeInstrumenter.new(This:C1470.hostStorage)
		
		// Parse coverage method patterns
		This:C1470._parseCoverageMethods()
	End if 
	
Function _parseCoverageMethods()
	// Parse which methods to track for coverage
	var $methodsParam : Text
	$methodsParam:=This:C1470.userParams.coverageMethods || ""
	
	If ($methodsParam="")
		// Default: discover all project methods and class methods
		This:C1470.coverageMethods:=This:C1470._discoverCoverableMethods()
	Else 
		// Parse comma-separated list of method patterns
		This:C1470.coverageMethods:=Split string:C1554($methodsParam; ",")
	End if 
	
Function _discoverCoverableMethods() : Collection
	// Discover all methods that should be tracked for coverage
	// This should be implemented to find host project methods
	var $methods : Collection
	$methods:=[]
	
	// Get all project methods
	ARRAY TEXT:C222($methodNames; 0)
	METHOD GET NAMES:C1166($methodNames; *)
	
	var $i : Integer
	For ($i; 1; Size of array:C274($methodNames))
		var $methodPath : Text
		$methodPath:=$methodNames{$i}
		
		// Skip test methods and framework methods
		If (This:C1470._shouldTrackMethodForCoverage($methodPath))
			$methods.push($methodPath)
		End if 
	End for 
	
	return $methods
	
Function _shouldTrackMethodForCoverage($methodPath : Text) : Boolean
	// Determine if a method should be tracked for coverage
	
	// Skip test-related methods
	If ($methodPath="@Test@") || ($methodPath="Test@")
		return False:C215
	End if 
	
	// Skip testing framework methods
	If ($methodPath="Testing_@") || ($methodPath="TestErrorHandler") || ($methodPath="TestGlobalErrorHandler")
		return False:C215
	End if 
	
	// Skip methods starting with underscore (private/utility methods)
	If ($methodPath="_@")
		return False:C215
	End if 
	
	return True:C214
	
Function _setupCoverage()
	// Setup coverage tracking before running tests
	If (Not:C34(This:C1470.coverageEnabled))
		return 
	End if 
	
	// Initialize coverage tracker
	This:C1470.coverageTracker.initialize()
	
	// Instrument methods
	If (This:C1470.coverageMethods.length>0)
		var $stats : Object
		$stats:=This:C1470.coverageInstrumenter.instrumentMethods(This:C1470.coverageMethods)
		
		If (This:C1470.outputFormat="human")
			LOG EVENT:C667(Into system standard outputs:K38:9; "Coverage: Instrumented "+String:C10($stats.success)+" methods\r\n"; Information message:K38:1)
			If ($stats.failed>0)
				LOG EVENT:C667(Into system standard outputs:K38:9; "Coverage: Failed to instrument "+String:C10($stats.failed)+" methods\r\n"; Warning message:K38:2)
			End if 
		End if 
	End if 
	
Function _teardownCoverage()
	// Teardown coverage tracking after running tests
	If (Not:C34(This:C1470.coverageEnabled))
		return 
	End if 
	
	// Collect coverage data
	This:C1470.coverageTracker.collectData()
	
	// Restore original code
	This:C1470.coverageInstrumenter.restoreOriginalCode()
	
	// Generate coverage report
	This:C1470._generateCoverageReport()
	
	// Cleanup
	This:C1470.coverageTracker.cleanup()
	
Function _generateCoverageReport()
	// Generate coverage report in requested format
	If (This:C1470.coverageReporter=Null:C1517)
		This:C1470.coverageReporter:=cs:C1710.CoverageReporter.new(This:C1470.coverageTracker; This:C1470.coverageInstrumenter)
	End if 
	
	var $coverageFormat : Text
	$coverageFormat:=This:C1470.userParams.coverageFormat || "text"
	
	var $coverageOutput : Text
	$coverageOutput:=This:C1470.userParams.coverageOutput || ""
	
	// Generate and display/save report
	If ($coverageOutput#"")
		// Write to file
		This:C1470.coverageReporter.writeReportToFile($coverageFormat; $coverageOutput)
		
		If (This:C1470.outputFormat="human")
			LOG EVENT:C667(Into system standard outputs:K38:9; "Coverage report written to: "+$coverageOutput+"\r\n"; Information message:K38:1)
		End if 
	Else 
		// Display to console
		var $report : Text
		$report:=This:C1470.coverageReporter.generateReport($coverageFormat)
		
		If (This:C1470.outputFormat="human") || ($coverageFormat="text")
			LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"+$report+"\r\n"; Information message:K38:1)
		End if 
	End if 
	
	// Add coverage stats to test results
	This:C1470.results.coverage:=This:C1470.coverageTracker.getCoverageStats()
	This:C1470.results.coverageEnabled:=True:C214