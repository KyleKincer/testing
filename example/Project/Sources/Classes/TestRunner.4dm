property classStore : 4D:C1709.Object  // Class store from the calling project
property testSuites : Collection  // Collection of cs.TestSuite
property results : Object  // Test results summary

Class constructor($cs : 4D:C1709.Object)
	This:C1470.classStore:=$cs || cs:C1710
	This:C1470.testSuites:=[]
	This:C1470._initializeResults()
	
Function run()
	This:C1470._initializeResults()
	This:C1470.testSuites:=[]
	This:C1470.discoverTests()
	
	This:C1470.results.startTime:=Milliseconds:C459
	This:C1470._logHeader()
	
	var $testSuite : cs:C1710.TestSuite
	For each ($testSuite; This:C1470.testSuites)
		$testSuite.run()
		This:C1470._collectSuiteResults($testSuite)
	End for each 
	
	This:C1470.results.endTime:=Milliseconds:C459
	This:C1470.results.duration:=This:C1470.results.endTime-This:C1470.results.startTime
	This:C1470._generateReport()
	
Function discoverTests()
	var $class : 4D:C1709.Class
	For each ($class; This:C1470._getTestClasses())
		This:C1470.testSuites.push(cs:C1710.TestSuite.new($class))
	End for each 
	
Function _getTestClasses()->$classes : Collection
	// Returns collection of 4D.Class
	$classes:=[]
	var $className : Text
	For each ($className; This:C1470.classStore)
		// Skip Dataclasses for now
		If (This:C1470.classStore[$className].superclass.name="DataClass")
			continue
		End if 
		
		// Test classes end with "Test", e.g. "MyClassTest"
		If ($className="@Test")
			$classes.push(This:C1470.classStore[$className])
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
	LOG EVENT:C667(Into system standard outputs:K38:9; ""; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "=== 4D Unit Testing Framework ==="; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Running tests..."; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; ""; Information message:K38:1)
	
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
			LOG EVENT:C667(Into system standard outputs:K38:9; "  ✓ "+$testResult.name+" ("+String:C10($testResult.duration)+"ms)"; Information message:K38:1)
		Else 
			This:C1470.results.failed+=1
			$suiteResult.failed+=1
			This:C1470.results.failedTests.push($testResult)
			LOG EVENT:C667(Into system standard outputs:K38:9; "  ✗ "+$testResult.name+" ("+String:C10($testResult.duration)+"ms)"; Error message:K38:3)
		End if 
		
		$suiteResult.tests.push($testResult)
	End for each 
	
	This:C1470.results.suites.push($suiteResult)
	
Function _generateReport()
	var $passRate : Real
	If (This:C1470.results.totalTests>0)
		$passRate:=(This:C1470.results.passed/This:C1470.results.totalTests)*100
	Else 
		$passRate:=0
	End if 
	
	LOG EVENT:C667(Into system standard outputs:K38:9; ""; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "=== Test Results Summary ==="; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Total Tests: "+String:C10(This:C1470.results.totalTests); Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Passed: "+String:C10(This:C1470.results.passed); Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Failed: "+String:C10(This:C1470.results.failed); Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Pass Rate: "+String:C10($passRate; "##0.0")+"%"; Information message:K38:1)
	LOG EVENT:C667(Into system standard outputs:K38:9; "Duration: "+String:C10(This:C1470.results.duration)+"ms"; Information message:K38:1)
	
	If (This:C1470.results.failed>0)
		LOG EVENT:C667(Into system standard outputs:K38:9; ""; Information message:K38:1)
		LOG EVENT:C667(Into system standard outputs:K38:9; "=== Failed Tests ==="; Error message:K38:3)
		
		var $failedTest : Object
		For each ($failedTest; This:C1470.results.failedTests)
			LOG EVENT:C667(Into system standard outputs:K38:9; "- "+$failedTest.name; Error message:K38:3)
		End for each 
	End if 
	
	This:C1470._logFooter()
	
Function _logFooter()
	LOG EVENT:C667(Into system standard outputs:K38:9; ""; Information message:K38:1)
	If (This:C1470.results.failed=0)
		LOG EVENT:C667(Into system standard outputs:K38:9; "All tests passed! 🎉"; Information message:K38:1)
	Else 
		LOG EVENT:C667(Into system standard outputs:K38:9; String:C10(This:C1470.results.failed)+" test(s) failed"; Error message:K38:3)
	End if 
	LOG EVENT:C667(Into system standard outputs:K38:9; ""; Information message:K38:1)
	
Function getResults() : Object
	return This:C1470.results
	