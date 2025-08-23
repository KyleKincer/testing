Class extends TestRunner

// Additional properties for parallel execution
property parallelMode : Boolean
property maxWorkers : Integer
property workerProcesses : Collection  // Collection of worker process names
property workerSignals : Collection    // Signals for worker completion
property sharedResults : Object        // Shared storage for collecting results
property completedSuites : Integer     // Counter for completed suites
property sequentialSuites : Collection // Suites that opted out of parallel execution

Class constructor($cs : 4D:C1709.Object)
	Super:C1705($cs)
	This:C1470.parallelMode:=False:C215
        This:C1470.maxWorkers:=This:C1470._getDefaultWorkerCount()
        This:C1470.workerProcesses:=[]
        This:C1470.workerSignals:=[]
        This:C1470.completedSuites:=0
        This:C1470.sequentialSuites:=[]
        This:C1470._parseParallelOptions()
	
Function run()
	If (This:C1470.parallelMode)
		// Discover tests first to check if we have multiple suites
		This:C1470._initializeResults()
		This:C1470.testSuites:=[]
		This:C1470.discoverTests()
		
		If (This:C1470.testSuites.length>1)
			This:C1470._runParallel()
		Else
			// Fall back to sequential execution for single suite
			Super:C1706.run()
		End if
	Else
		// Fall back to sequential execution when parallel disabled
		Super:C1706.run()
	End if

Function _runParallel()
	// Set up global error handler for the test run
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	
	// Tests already discovered in run() method
	If (This:C1470.testSuites.length=0)
		This:C1470._generateReport()
		// Restore previous error handler
		If ($previousErrorHandler#"")
			ON ERR CALL:C155($previousErrorHandler)
		Else
			ON ERR CALL:C155("")
		End if
		return
	End if

	// Install handler only when we have work to do
	ON ERR CALL:C155("TestErrorHandler")
	This:C1470.results.startTime:=Milliseconds:C459
	
	If (This:C1470.outputFormat="human")
		This:C1470._logHeader()
		LOG EVENT:C667(Into system standard outputs:K38:9; "Running "+String:C10(This:C1470.testSuites.length)+" test suites in parallel (max "+String:C10(This:C1470.maxWorkers)+" workers)\r\n"; Information message:K38:1)
	End if
	
	// Initialize shared storage for parallel results
	This:C1470._initializeSharedStorage()
	
	// Execute test suites in parallel
	This:C1470._executeTestSuitesInParallel()
	
	// Wait for all workers to complete and collect results
	This:C1470._waitForCompletionAndCollectResults()
	
	This:C1470.results.endTime:=Milliseconds:C459
	This:C1470.results.duration:=This:C1470.results.endTime-This:C1470.results.startTime
	This:C1470._generateReport()
	
	// Clean up shared storage
	This:C1470._cleanupSharedStorage()
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else
		ON ERR CALL:C155("")
	End if

Function _parseParallelOptions()
	var $params : Object
	$params:=This:C1470._parseUserParams()
	
	// Check for parallel flag
	This:C1470.parallelMode:=($params.parallel="true")
	
	// Parse max workers if specified
	If ($params.maxWorkers#Null:C1517)
		var $maxWorkers : Integer
		$maxWorkers:=Num:C11($params.maxWorkers)
		If ($maxWorkers>0) && ($maxWorkers<=16)  // Reasonable limits
			This:C1470.maxWorkers:=$maxWorkers
		End if
	End if

Function _getDefaultWorkerCount() : Integer
	// Default to CPU count, but cap at reasonable maximum
	var $cpuCount : Integer
	$cpuCount:=System info:C1571.numberOfCores || 4  // Default to 4 if unable to detect
	return Num:C11(Choose:C955($cpuCount>8; 8; $cpuCount))  // Cap at 8 workers

Function _initializeSharedStorage()
	// Initialize shared storage with simple counters for result aggregation
	Use (Storage:C1525)
		Storage:C1525.parallelTestResults:=New shared object:C1526(\
			"completedCount"; 0; \
			"totalSuites"; This:C1470.testSuites.length; \
			"totalTests"; 0; \
			"passedTests"; 0; \
			"failedTests"; 0\
		)
	End use

Function _executeTestSuitesInParallel()
	// Create workers and distribute test suites among them
	var $workerCount : Integer
	var $workerName : Text
	$workerCount:=Num:C11(Choose:C955(This:C1470.testSuites.length<This:C1470.maxWorkers; This:C1470.testSuites.length; This:C1470.maxWorkers))
	
	// Create worker process names (workers will be created on-demand by CALL WORKER)
	var $i : Integer
	For ($i; 1; $workerCount)
		$workerName:="TestWorker_"+String:C10($i)+"_"+String:C10(Random:C100)
		This:C1470.workerProcesses.push($workerName)
	End for
	
	// Distribute test suites to workers, respecting parallel opt-out
	var $suiteIndex : Integer
	var $parallelSuites : Collection
	var $sequentialSuites : Collection
	$suiteIndex:=0
	$parallelSuites:=[]
	$sequentialSuites:=[]
	
	var $testSuite : cs:C1710._TestSuite
	For each ($testSuite; This:C1470.testSuites)
		If (This:C1470._shouldRunSuiteInParallel($testSuite))
			$parallelSuites.push($testSuite)
		Else
			$sequentialSuites.push($testSuite)
		End if
	End for each
	
        // Run parallel suites in workers and store signals
        This:C1470.workerSignals:=New collection:C1472
        var $parallelSuiteIndex : Integer
        $parallelSuiteIndex:=0

        For each ($testSuite; $parallelSuites)
                $workerName:=This:C1470.workerProcesses[$parallelSuiteIndex % $workerCount]

                // Create a signal for this worker task
                var $signal : 4D:C1709.Signal
                $signal:=New signal:C1641
                This:C1470.workerSignals.push($signal)

                // Send test suite to worker via CALL WORKER with signal
                var $suiteData : Object
                $suiteData:=New object:C1471(\
                        "class"; $testSuite.class; \
                        "outputFormat"; $testSuite.outputFormat; \
                        "testPatterns"; $testSuite.testPatterns; \
                        "testRunner"; This:C1470; \
                        "suiteIndex"; $parallelSuiteIndex; \
                        "signal"; $signal\
                )

                CALL WORKER:C1389($workerName; "ParallelTestWorker"; "ExecuteTestSuite"; $suiteData)
                $parallelSuiteIndex:=$parallelSuiteIndex+1
        End for each

        // Run sequential suites in main process after parallel ones complete
        If ($sequentialSuites.length>0)
                // These will be run after parallel completion in _waitForCompletionAndCollectResults
                This:C1470.sequentialSuites:=$sequentialSuites
        End if

Function _waitForCompletionAndCollectResults()
	// Wait for parallel test suites to complete
	var $parallelSuiteCount : Integer
	var $totalSuites : Integer
	
	Use (Storage:C1525.parallelTestResults)
		$totalSuites:=Storage:C1525.parallelTestResults.totalSuites
	End use
	
	$parallelSuiteCount:=$totalSuites-This:C1470.sequentialSuites.length
	
        If ($parallelSuiteCount>0)
                var $startWait : Integer
                $startWait:=Milliseconds:C459
                var $timeout : Integer
                $timeout:=300000  // 5 minute timeout
		
		var $completedCount : Integer
		$completedCount:=0
		
		While ($completedCount<$parallelSuiteCount)
			Use (Storage:C1525.parallelTestResults)
				$completedCount:=Storage:C1525.parallelTestResults.completedCount
			End use
			
			If ((Milliseconds:C459-$startWait)>$timeout)
				// Timeout - log error and break
				LOG EVENT:C667(Into system standard outputs:K38:9; "Parallel test execution timeout after 5 minutes\r\n"; Error message:K38:3)
				break
			End if
			
			DELAY PROCESS:C323(Current process:C322; 10)  // Wait 10 ticks
                End while

        End if

        // Collect results from worker signals
        This:C1470._aggregateParallelResults()

        // Run sequential suites in main process
        If (This:C1470.sequentialSuites.length>0)
                If (This:C1470.outputFormat="human")
                        LOG EVENT:C667(Into system standard outputs:K38:9; "Running "+String:C10(This:C1470.sequentialSuites.length)+" sequential test suite(s)\r\n"; Information message:K38:1)
		End if
		
		var $testSuite : cs:C1710._TestSuite
		For each ($testSuite; This:C1470.sequentialSuites)
			$testSuite.run()
			This:C1470._collectSuiteResults($testSuite)
		End for each
	End if
	
	// Cleanup worker processes
	For each ($workerName; This:C1470.workerProcesses)
		CALL WORKER:C1389($workerName; "ParallelTestWorker"; "StopWorker")
	End for each

Function _processWorkerResults($suiteResults : Object)
	// Process detailed results from a worker signal
	// Copy shared objects to regular objects for safe processing
	var $suiteResult : Object
	$suiteResult:=OB Copy:C1225($suiteResults; ck resolve pointers:K85:26)
	
	This:C1470.results.suites.push($suiteResult)
	
	// Process individual test results for detailed tracking and immediate output
	If ($suiteResult.tests#Null:C1517)
		var $test : Object
		For each ($test; $suiteResult.tests)
			This:C1470.results.totalTests+=1
			
			If ($test.passed)
				This:C1470.results.passed+=1
				If (This:C1470.outputFormat="human")
					LOG EVENT:C667(Into system standard outputs:K38:9; "  ✓ "+$test.name+" ("+String:C10($test.duration)+"ms)\r\n"; Information message:K38:1)
				End if
			Else
				This:C1470.results.failed+=1
				var $failedTest : Object
				$failedTest:=OB Copy:C1225($test; ck resolve pointers:K85:26)
				This:C1470.results.failedTests.push($failedTest)
				
				If (This:C1470.outputFormat="human")
					var $errorDetails : Text
					$errorDetails:=""
					
					// Check for runtime errors first
					If ($test.runtimeErrors#Null:C1517) && ($test.runtimeErrors.length>0)
						$errorDetails:=" [Runtime Error: "+$test.runtimeErrors[0].text+"]"
					Else
						// Check for failure reason or log messages
						If ($test.failureReason#Null:C1517) && ($test.failureReason#"")
							$errorDetails:=" ["+$test.failureReason+"]"
						Else
							If ($test.logMessages#Null:C1517) && ($test.logMessages.length>0)
								$errorDetails:=" ["+$test.logMessages[0]+"]"
							End if
						End if
					End if
					
					LOG EVENT:C667(Into system standard outputs:K38:9; "  ✗ "+$test.name+" ("+String:C10($test.duration)+"ms)"+$errorDetails+"\r\n"; Error message:K38:3)
				End if
			End if
		End for each
	End if

Function _aggregateParallelResults()
        // Process results from all worker signals after completion
        If (This:C1470.workerSignals#Null:C1517)
                var $workerSignal : 4D:C1709.Signal
                For each ($workerSignal; This:C1470.workerSignals)
                        If ($workerSignal.suiteResults#Null:C1517)
                                This:C1470._processWorkerResults($workerSignal.suiteResults)
                        Else
                                If (This:C1470.outputFormat="human")
                                        LOG EVENT:C667(Into system standard outputs:K38:9; "Warning: Worker completed but no results received\r\n"; Information message:K38:1)
                                End if
                        End if
                End for each
        End if

Function _cleanupSharedStorage()
	// Clean up shared storage
	Use (Storage:C1525)
		Storage:C1525.parallelTestResults:=Null:C1517
	End use

Function _shouldRunSuiteInParallel($testSuite : cs:C1710._TestSuite) : Boolean
	// Check if suite should run in parallel (allow opt-out via comments)
	var $classCode : Text
	$classCode:=$testSuite._getClassCode()
	
	// Look for class-level parallel control comment
	// Format: // #parallel: false
	If ($classCode#"")
		var $lines : Collection
		$lines:=Split string:C1554($classCode; Char:C90(Carriage return:K15:38))
		
		var $line : Text
		For each ($line; $lines)
			// Look for #parallel: comments
			If (Position:C15("#parallel:"; $line)>0)
				var $parallelValue : Text
				$parallelValue:=Substring:C12($line; Position:C15("#parallel:"; $line)+10)
				$parallelValue:=Replace string:C233($parallelValue; " "; "")  // Remove spaces
				
				// Check for explicit disable
				If ($parallelValue="false")
					return False:C215
				End if
			End if
		End for each
	End if
	
	return True:C214  // Default to parallel execution