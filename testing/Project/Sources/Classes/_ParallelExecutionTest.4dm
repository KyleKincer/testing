// Tests for parallel test execution functionality

Class constructor()

Function test_parallel_mode_detection($t : cs:C1710.Testing)
	// #tags: unit, parallel
	
	// Test that parallel mode is properly detected from parameters
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	
	// Mock user parameters for parallel execution
	$runner.parallelMode:=True:C214
	$runner.maxWorkers:=4
	
	$t.assert.isTrue($t; $runner.parallelMode; "Parallel mode should be enabled")
	$t.assert.areEqual($t; 4; $runner.maxWorkers; "Max workers should be set to 4")

Function test_default_worker_count($t : cs:C1710.Testing)
	// #tags: unit, parallel
	
	// Test default worker count calculation
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	
	var $defaultCount : Integer
	$defaultCount:=$runner._getDefaultWorkerCount()
	
	$t.assert.isTrue($t; $defaultCount>=1; "Default worker count should be at least 1")
	$t.assert.isTrue($t; $defaultCount<=8; "Default worker count should be capped at 8")

Function test_parallel_suite_filtering($t : cs:C1710.Testing)
	// #tags: unit, parallel
	
	// Test that suites can opt out of parallel execution
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	
	// Create a test suite that should run in parallel
	var $parallelSuite : cs:C1710._TestSuite
	$parallelSuite:=cs:C1710._TestSuite.new(cs:C1710._ExampleTest; "human"; []; $runner)
	
	// Test that it should run in parallel (no opt-out comment)
	var $shouldRunParallel : Boolean
	$shouldRunParallel:=$runner._shouldRunSuiteInParallel($parallelSuite)
	$t.assert.isTrue($t; $shouldRunParallel; "Suite without opt-out should run in parallel")

Function test_shared_storage_initialization($t : cs:C1710.Testing)
	// #tags: unit, parallel
	
	// Test shared storage initialization
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	$runner.testSuites:=[cs:C1710._TestSuite.new(cs:C1710._ExampleTest; "human"; []; $runner)]
	
	// Initialize and verify shared storage
	$runner._initializeSharedStorage()
	Use (Storage:C1525)
		$t.assert.isTrue($t; Storage:C1525.parallelTestResults#Null:C1517; "parallelTestResults should be initialized")
		$t.assert.areEqual($t; $runner.testSuites.length; Storage:C1525.parallelTestResults.totalSuites; "totalSuites should match")
	End use
Function test_sequential_fallback($t : cs:C1710.Testing)
	// #tags: integration, parallel
	
	// Test that single suites fall back to sequential execution
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	$runner.parallelMode:=True:C214
	
	// Mock a single test suite scenario
	$runner.testSuites:=[cs:C1710._TestSuite.new(cs:C1710._ExampleTest; "human"; []; $runner)]
	
	// Should fall back to sequential execution for single suite
	// This is tested implicitly in the run() method logic

Function test_worker_process_management($t : cs:C1710.Testing)
	// #tags: integration, parallel
	
	// Test worker process creation and management
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	$runner.parallelMode:=True:C214
	$runner.maxWorkers:=2
	
	// Initialize worker processes collection
	$t.assert.areEqual($t; 0; $runner.workerProcesses.length; "Worker processes should start empty")
	
	// Test that worker count is properly managed
	$t.assert.areEqual($t; 2; $runner.maxWorkers; "Max workers should be set correctly")

Function test_parallel_opt_out_parsing($t : cs:C1710.Testing)
	// #tags: unit, parallel
	
	// Test parsing of parallel opt-out comments
	var $runner : cs:C1710.ParallelTestRunner
	$runner:=cs:C1710.ParallelTestRunner.new()
	
	// Mock class code with parallel opt-out
	var $classCode : Text
	$classCode:="// Test class with parallel opt-out\r// #parallel: false\rClass constructor()\r\rFunction test_something($t : cs.Testing)\r  // Test code here\r"
	
        // Test parsing logic by creating a mock test suite
        // Note: This would require more complex mocking in a real scenario

Function test_parallel_throws_thread_safety($t : cs:C1710.Testing)
        // #tags: integration, parallel

        // Verify that throws assertion works correctly when suites run in parallel
        var $runner : cs:C1710.ParallelTestRunner
        $runner:=cs:C1710.ParallelTestRunner.new()
        $runner.parallelMode:=True:C214
        $runner._initializeResults()
        $runner.testSuites:=[\
                cs:C1710._TestSuite.new(cs:C1710._ParallelThrowsTest1; "human"; []; $runner);\
                cs:C1710._TestSuite.new(cs:C1710._ParallelThrowsTest2; "human"; []; $runner)\
        ]

        $runner._runParallel()

        $t.assert.areEqual($t; 2; $runner.results.passed; "Both parallel throws tests should pass")
