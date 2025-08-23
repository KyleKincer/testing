//%attributes = {}
#DECLARE($command : Text; $data : Object)
// Worker method for parallel test execution
// Called by CALL WORKER from ParallelTestRunner

Case of 
	: ($command="ExecuteTestSuite")
		// Execute test suite with provided data
		// Recreate test suite in this worker process
		var $testSuite : cs:C1710._TestSuite
		$testSuite:=cs:C1710._TestSuite.new(\
			$data.class; \
			$data.outputFormat; \
			$data.testPatterns; \
			$data.testRunner\
			)
		
		// Set up error handler for this worker
		var $previousErrorHandler : Text
		$previousErrorHandler:=Method called on error:C704
		ON ERR CALL:C155("TestErrorHandler")
		
		// Run the test suite
		$testSuite.run()
		
		// Collect detailed test results from completed test suite (using regular objects)
		var $suiteResults : Object
		$suiteResults:=New object:C1471(\
			"name"; String:C10($testSuite.class.name); \
			"tests"; New collection:C1472; \
			"passed"; 0; \
			"failed"; 0\
			)
		
		var $testFunction : cs:C1710._TestFunction
		For each ($testFunction; $testSuite.testFunctions)
			var $testResult : Object
			$testResult:=$testFunction.getResult()
			
			// Create a clean result object for transport
			var $cleanResult : Object
			$cleanResult:=New object:C1471(\
				"name"; String:C10($testResult.name); \
				"passed"; Bool:C1537($testResult.passed); \
				"failed"; Bool:C1537($testResult.failed); \
				"duration"; Num:C11($testResult.duration); \
				"suite"; String:C10($testResult.suite)\
				)
			
			// Add failure details if test failed
			If ($testResult.failed)
				// Get failure reason from log messages or default message
				var $failureReason : Text
				$failureReason:="Test failed"
				If ($testResult.logMessages#Null:C1517)
					If ($testResult.logMessages.length>0)
						$failureReason:=String:C10($testResult.logMessages[0])
					End if 
				End if 
				$cleanResult.failureReason:=$failureReason
				
				$cleanResult.runtimeErrors:=New collection:C1472
				If ($testResult.runtimeErrors#Null:C1517)
					var $error : Object
					For each ($error; $testResult.runtimeErrors)
						$cleanResult.runtimeErrors.push(New object:C1471(\
							"errorCode"; Num:C11($error.errorCode); \
							"text"; String:C10($error.text); \
							"method"; String:C10($error.method)\
							))
					End for each 
				End if 
				
				// Also include log messages for debugging
				$cleanResult.logMessages:=New collection:C1472
				If ($testResult.logMessages#Null:C1517)
					var $logMessage : Text
					For each ($logMessage; $testResult.logMessages)
						$cleanResult.logMessages.push(String:C10($logMessage))
					End for each 
				End if 
			End if 
			
			$suiteResults.tests.push($cleanResult)
			
			If ($testResult.passed)
				$suiteResults.passed+=1
			Else 
				$suiteResults.failed+=1
			End if 
		End for each 
		
		// Update shared counters for summary
		Use (Storage:C1525.parallelTestResults)
			Storage:C1525.parallelTestResults.completedCount+=1
			Storage:C1525.parallelTestResults.totalTests+=$suiteResults.tests.length
			Storage:C1525.parallelTestResults.passedTests+=$suiteResults.passed
			Storage:C1525.parallelTestResults.failedTests+=$suiteResults.failed
		End use 
		
		// Attach detailed results to signal and trigger completion
		If ($data.signal#Null:C1517)
			Use ($data.signal)
				// Convert regular object to shared object for signal transport
				$data.signal.suiteResults:=OB Copy:C1225($suiteResults; ck shared:K85:29; $data.signal)
			End use 
			$data.signal.trigger()
		End if 
		
		// Restore previous error handler
		If ($previousErrorHandler#"")
			ON ERR CALL:C155($previousErrorHandler)
		Else 
			ON ERR CALL:C155("")
		End if 
		
	: ($command="StopWorker")
		KILL WORKER:C1390
		
End case 