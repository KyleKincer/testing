// Tests for code coverage functionality
// #tags: unit, coverage

Class constructor()
	
Function test_tracker_initialization($t : cs.Testing)
	// Test that CoverageTracker initializes correctly
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	$t.assert.areEqual(False; $tracker.enabled; "Tracker should start disabled")
	$t.assert.isNotNull($tracker.methodCoverage; "Method coverage map should exist")
	
Function test_tracker_enable_disable($t : cs.Testing)
	// Test enabling and disabling coverage tracking
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	$tracker.enable()
	$t.assert.areEqual(True; $tracker.enabled; "Tracker should be enabled")
	$t.assert.isTrue($tracker.startTime>0; "Start time should be recorded")
	
	$tracker.disable()
	$t.assert.areEqual(False; $tracker.enabled; "Tracker should be disabled")
	$t.assert.isTrue($tracker.endTime>0; "End time should be recorded")
	
Function test_tracker_clear($t : cs.Testing)
	// Test clearing coverage data
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	$tracker.enable()
	$tracker.clear()
	
	var $results : Object
	$results:=$tracker.collectResults()
	
	$t.assert.areEqual(0; OB Keys($results.methodCoverage).length; "Coverage data should be empty")
	
Function test_instrumenter_initialization($t : cs.Testing)
	// Test that CodeInstrumenter initializes correctly
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	$t.assert.isNotNull($instrumenter.originalCode; "Original code map should exist")
	$t.assert.isNotNull($instrumenter.instrumentedMethods; "Instrumented methods list should exist")
	$t.assert.areEqual(0; $instrumenter.instrumentedMethods.length; "Should start with no instrumented methods")
	
Function test_instrumenter_isExecutableLine($t : cs.Testing)
	// Test executable line detection
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	// Executable lines
	$t.assert.isTrue($instrumenter._isExecutableLine("var $x : Integer"); "Variable declaration is executable")
	$t.assert.isTrue($instrumenter._isExecutableLine("$x:=10"); "Assignment is executable")
	$t.assert.isTrue($instrumenter._isExecutableLine("return $x"); "Return is executable")
	
	// Non-executable lines
	$t.assert.isFalse($instrumenter._isExecutableLine(""); "Empty line is not executable")
	$t.assert.isFalse($instrumenter._isExecutableLine("// Comment"); "Comment is not executable")
	$t.assert.isFalse($instrumenter._isExecutableLine("Function test()"); "Function signature is not executable")
	$t.assert.isFalse($instrumenter._isExecutableLine("End if"); "End if is not executable")
	$t.assert.isFalse($instrumenter._isExecutableLine("Else"); "Else is not executable")
	
Function test_reporter_initialization($t : cs.Testing)
	// Test that CoverageReporter initializes correctly
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	var $reporter : cs.CoverageReporter
	$reporter:=cs.CoverageReporter.new($tracker; $instrumenter)
	
	$t.assert.isNotNull($reporter.tracker; "Reporter should have tracker reference")
	$t.assert.isNotNull($reporter.instrumenter; "Reporter should have instrumenter reference")
	
Function test_reporter_calculateCoverage($t : cs.Testing)
	// Test coverage calculation with no data
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	var $reporter : cs.CoverageReporter
	$reporter:=cs.CoverageReporter.new($tracker; $instrumenter)
	
	var $report : Object
	$report:=$reporter.calculateCoverage()
	
	$t.assert.isNotNull($report.summary; "Report should have summary")
	$t.assert.areEqual(0; $report.summary.totalLines; "Should have 0 total lines")
	$t.assert.areEqual(0; $report.summary.coveredLines; "Should have 0 covered lines")
	
Function test_reporter_generateTextReport($t : cs.Testing)
	// Test text report generation
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	var $reporter : cs.CoverageReporter
	$reporter:=cs.CoverageReporter.new($tracker; $instrumenter)
	
	var $textReport : Text
	$textReport:=$reporter.generateTextReport()
	
	$t.assert.isTrue(Position("Code Coverage Report"; $textReport)>0; "Report should contain title")
	$t.assert.isTrue(Position("Overall Coverage"; $textReport)>0; "Report should contain summary")
	
Function test_reporter_generateJSONReport($t : cs.Testing)
	// Test JSON report generation
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	var $reporter : cs.CoverageReporter
	$reporter:=cs.CoverageReporter.new($tracker; $instrumenter)
	
	var $jsonReport : Text
	$jsonReport:=$reporter.generateJSONReport()
	
	// Parse JSON to verify it's valid
	var $parsed : Object
	$parsed:=JSON Parse($jsonReport)
	
	$t.assert.isNotNull($parsed; "JSON should be valid")
	$t.assert.isNotNull($parsed.summary; "JSON should contain summary")
	
Function test_instrumenter_trim($t : cs.Testing)
	// Test the trim utility function
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	$t.assert.areEqual("test"; $instrumenter._trim("  test  "); "Should trim spaces")
	$t.assert.areEqual("test"; $instrumenter._trim("\ttest\t"); "Should trim tabs")
	$t.assert.areEqual("test"; $instrumenter._trim("test"); "Should handle no whitespace")
	$t.assert.areEqual(""; $instrumenter._trim("   "); "Should trim all spaces")
	
Function test_instrumenter_extractFunctionName($t : cs.Testing)
	// Test function name extraction
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	$t.assert.areEqual("test"; $instrumenter._extractFunctionName("Function test()"); "Should extract simple function name")
	$t.assert.areEqual("test"; $instrumenter._extractFunctionName("Function test($param : Text)"); "Should extract with params")
	$t.assert.areEqual("test"; $instrumenter._extractFunctionName("Function test : Integer"); "Should extract with return type")
	
Function test_instrumenter_isFrameworkClass($t : cs.Testing)
	// Test framework class detection
	
	var $tracker : cs.CoverageTracker
	$tracker:=cs.CoverageTracker.new()
	
	var $instrumenter : cs.CodeInstrumenter
	$instrumenter:=cs.CodeInstrumenter.new(cs; $tracker)
	
	$t.assert.isTrue($instrumenter._isFrameworkClass("TestRunner"); "TestRunner is framework class")
	$t.assert.isTrue($instrumenter._isFrameworkClass("Assert"); "Assert is framework class")
	$t.assert.isTrue($instrumenter._isFrameworkClass("_ExampleTest"); "Test classes with underscore are framework")
	$t.assert.isFalse($instrumenter._isFrameworkClass("MyClass"); "Regular classes are not framework")
