property classStore : 4D:C1709.Object  // Class store from the calling project
property testSuites : Collection  // Collection of cs.TestSuite
property results : Object  // Test results summary
property outputFormat : Text  // "human" or "json"
property verboseOutput : Boolean  // Whether to include detailed information
property testPatterns : Collection  // Collection of test patterns to match
property includeTags : Collection  // Tags to include (OR logic)
property excludeTags : Collection  // Tags to exclude
property requireAllTags : Collection  // Tags that must all be present (AND logic)

Class constructor($cs : 4D:C1709.Object)
	This:C1470.classStore:=$cs || cs:C1710
	This:C1470.testSuites:=[]
	This:C1470._initializeResults()
	This:C1470._determineOutputFormat()
	This:C1470._parseTestPatterns()
	This:C1470._parseTagFilters()
	
Function run()
	// Set up global error handler for the test run
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	This:C1470._initializeResults()
	This:C1470.testSuites:=[]
	This:C1470.discoverTests()
	
	This:C1470.results.startTime:=Milliseconds:C459
	
	If (This:C1470.outputFormat="human")
		This:C1470._logHeader()
	End if 
	
	var $testSuite : cs:C1710.TestSuite
	For each ($testSuite; This:C1470.testSuites)
		$testSuite.run()
		This:C1470._collectSuiteResults($testSuite)
	End for each 
	
	This:C1470.results.endTime:=Milliseconds:C459
	This:C1470.results.duration:=This:C1470.results.endTime-This:C1470.results.startTime
	This:C1470._generateReport()
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
Function discoverTests()
	var $class : 4D:C1709.Class
	For each ($class; This:C1470._getTestClasses())
		var $testSuite : cs:C1710.TestSuite
		$testSuite:=cs:C1710.TestSuite.new($class; This:C1470.outputFormat; This:C1470.testPatterns; This:C1470)
		
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
		"failedTests"; []\
		)
	
Function _logHeader()
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "=== 4D Unit Testing Framework ===\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Running tests...\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	
Function _collectSuiteResults($testSuite : cs:C1710.TestSuite)
	var $suiteResult : Object
	$suiteResult:=New object:C1471(\
		"name"; $testSuite.class.name; \
		"tests"; []; \
		"passed"; 0; \
		"failed"; 0\
		)
	
	var $testFunction : cs:C1710.TestFunction
	For each ($testFunction; $testSuite.testFunctions)
		var $testResult : Object
		$testResult:=$testFunction.getResult()
		
		This:C1470.results.totalTests+=1
		
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
				LOG EVENT:C667(Into system standard outputs:K38:9; "  ✗ "+$testResult.name+" ("+String:C10($testResult.duration)+"ms)"+$errorDetails+"\r\n"; Error message:K38:3)
			End if 
		End if 
		
		$suiteResult.tests.push($testResult)
	End for each 
	
	This:C1470.results.suites.push($suiteResult)
	
Function _generateReport()
	If (This:C1470.outputFormat="json")
		This:C1470._generateJSONReport()
	Else 
		This:C1470._generateHumanReport()
	End if 
	
Function _generateHumanReport()
	var $passRate : Real
	If (This:C1470.results.totalTests>0)
		$passRate:=(This:C1470.results.passed/This:C1470.results.totalTests)*100
	Else 
		$passRate:=0
	End if 
	
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "=== Test Results Summary ===\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Total Tests: "+String:C10(This:C1470.results.totalTests)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Passed: "+String:C10(This:C1470.results.passed)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Failed: "+String:C10(This:C1470.results.failed)+"\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Pass Rate: "+String:C10($passRate; "##0.0")+"%\r\n"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Duration: "+String:C10(This:C1470.results.duration)+"ms\r\n"; Information message:K38:1)
	
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
		End for each 
	End if 
	
	This:C1470._logFooter()
	
Function _generateJSONReport()
	var $passRate : Real
	If (This:C1470.results.totalTests>0)
		$passRate:=(This:C1470.results.passed/This:C1470.results.totalTests)*100
	Else 
		$passRate:=0
	End if 
	
	var $jsonReport : Object
	
	If (This:C1470.verboseOutput)
		// Verbose mode: include all details (original format)
		$jsonReport:=OB Copy:C1225(This:C1470.results)
		$jsonReport.passRate:=$passRate
		$jsonReport.status:=(This:C1470.results.failed=0) ? "success" : "failure"
	Else 
		// Terse mode: minimal information
		$jsonReport:=New object:C1471(\
			"tests"; This:C1470.results.totalTests; \
			"passed"; This:C1470.results.passed; \
			"failed"; This:C1470.results.failed; \
			"rate"; Round:C94($passRate; 1); \
			"duration"; This:C1470.results.duration; \
			"status"; (This:C1470.results.failed=0) ? "ok" : "fail"\
		)
		
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
				$failedTests.push($terseFailure)
			End for each 
			$jsonReport.failures:=$failedTests
		End if 
		
		// Only include suite summary if there are multiple suites
		If (This:C1470.results.suites.length>1)
			var $suiteSummary : Collection
			$suiteSummary:=[]
			var $suite : Object
			For each ($suite; This:C1470.results.suites)
				$suiteSummary.push(New object:C1471(\
					"name"; $suite.name; \
					"passed"; $suite.passed; \
					"failed"; $suite.failed\
				))
			End for each 
			$jsonReport.suites:=$suiteSummary
		End if 
	End if 
	
	var $jsonString : Text
	$jsonString:=JSON Stringify:C1217($jsonReport; *)
	
	LOG EVENT:C667(Into system standard outputs:K38:9; $jsonString; Information message:K38:1)
	
Function _logFooter()
	LOG EVENT:C667(Into system standard outputs:K38:9; "\r\n"; Information message:K38:1)
	If (This:C1470.results.failed=0)
		LOG EVENT:C667(Into system standard outputs:K38:9; "All tests passed! 🎉\r\n"; Information message:K38:1)
	Else 
		LOG EVENT:C667(Into system standard outputs:K38:9; String:C10(This:C1470.results.failed)+" test(s) failed\r\n"; Error message:K38:3)
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
		This:C1470.outputFormat:="human"
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
	
Function _shouldIncludeTestSuite($testSuite : cs:C1710.TestSuite) : Boolean
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
	
Function _patternMatchesAnyTestInSuite($testSuite : cs:C1710.TestSuite; $pattern : Text) : Boolean
	var $testFunction : cs:C1710.TestFunction
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

Function _shouldIncludeTestByTags($testFunction : cs:C1710.TestFunction) : Boolean
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