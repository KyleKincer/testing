// Tests for code coverage functionality
// #tags: unit, coverage

Class constructor()
	
Function test_coverageTracker_initialization($t : cs:C1710.Testing)
	// Test that CoverageTracker initializes correctly
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	
	$t.assert.isNotNull($tracker)
	$t.assert.isNotNull($tracker.coverageData)
	$t.assert.areEqual(0; $tracker.startTime)
	$t.assert.areEqual(0; $tracker.endTime)
	
Function test_coverageTracker_initialize($t : cs:C1710.Testing)
	// Test that initialize() sets up shared storage
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	$t.assert.isNotNull(Storage:C1525.coverage)
	$t.assert.isNotNull(Storage:C1525.coverage.data)
	$t.assert.isTrue($tracker.startTime>0)
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageTracker_recordLine($t : cs:C1710.Testing)
	// Test that recordLine() tracks line execution
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Record some lines
	$tracker.recordLine("TestMethod"; 1)
	$tracker.recordLine("TestMethod"; 2)
	$tracker.recordLine("TestMethod"; 1)  // Record line 1 again
	
	// Collect data
	$tracker.collectData()
	
	var $methodCoverage : Object
	$methodCoverage:=$tracker.getMethodCoverage("TestMethod")
	
	$t.assert.areEqual(2; Num:C11($methodCoverage["1"]))  // Line 1 hit twice
	$t.assert.areEqual(1; Num:C11($methodCoverage["2"]))  // Line 2 hit once
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageTracker_getCoverageStats($t : cs:C1710.Testing)
	// Test coverage statistics calculation
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Record some lines
	$tracker.recordLine("TestMethod"; 1)
	$tracker.recordLine("TestMethod"; 2)
	$tracker.recordLine("TestMethod"; 3)
	$tracker.recordLine("AnotherMethod"; 1)
	
	// Collect data
	$tracker.collectData()
	
	var $stats : Object
	$stats:=$tracker.getCoverageStats()
	
	$t.assert.areEqual(4; $stats.totalLines)  // 3 lines in TestMethod + 1 in AnotherMethod
	$t.assert.areEqual(4; $stats.coveredLines)  // All lines covered
	$t.assert.areEqual(0; $stats.uncoveredLines)
	$t.assert.areEqual(100; $stats.coveragePercent)
	$t.assert.areEqual(2; $stats.methodCount)
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageTracker_getUncoveredLines($t : cs:C1710.Testing)
	// Test identification of uncovered lines
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Record some lines but not all
	$tracker.recordLine("TestMethod"; 1)
	$tracker.recordLine("TestMethod"; 3)
	$tracker.recordLine("TestMethod"; 5)
	
	// Manually add uncovered lines to coverage data
	$tracker.collectData()
	$tracker.coverageData["TestMethod"]["2"]:=0
	$tracker.coverageData["TestMethod"]["4"]:=0
	
	var $uncoveredLines : Collection
	$uncoveredLines:=$tracker.getUncoveredLines("TestMethod")
	
	$t.assert.areEqual(2; $uncoveredLines.length)
	$t.assert.isTrue($uncoveredLines.includes(2))
	$t.assert.isTrue($uncoveredLines.includes(4))
	
	// Cleanup
	$tracker.cleanup()
	
Function test_codeInstrumenter_initialization($t : cs:C1710.Testing)
	// Test that CodeInstrumenter initializes correctly
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	$t.assert.isNotNull($instrumenter)
	$t.assert.isNotNull($instrumenter.originalCode)
	$t.assert.isNotNull($instrumenter.instrumentedMethods)
	$t.assert.areEqual(0; $instrumenter.instrumentedMethods.length)
	
Function test_codeInstrumenter_isExecutableLine($t : cs:C1710.Testing)
	// Test executable line detection
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	// Executable lines
	$t.assert.isTrue($instrumenter._isExecutableLine("$var:=123"; False:C215))
	$t.assert.isTrue($instrumenter._isExecutableLine("  If ($condition)"; False:C215))
	$t.assert.isTrue($instrumenter._isExecutableLine("METHOD CALL"; False:C215))
	
	// Non-executable lines
	$t.assert.isFalse($instrumenter._isExecutableLine("// Comment"; False:C215))
	$t.assert.isFalse($instrumenter._isExecutableLine(""; False:C215))
	$t.assert.isFalse($instrumenter._isExecutableLine("End if"; False:C215))
	$t.assert.isFalse($instrumenter._isExecutableLine("Function test()"; False:C215))
	$t.assert.isFalse($instrumenter._isExecutableLine("property name : Text"; False:C215))
	
Function test_codeInstrumenter_getLineIndentation($t : cs:C1710.Testing)
	// Test indentation extraction
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	$t.assert.areEqual(""; $instrumenter._getLineIndentation("NoIndent"))
	$t.assert.areEqual("  "; $instrumenter._getLineIndentation("  TwoSpaces"))
	$t.assert.areEqual("    "; $instrumenter._getLineIndentation("    FourSpaces"))
	$t.assert.areEqual("\t"; $instrumenter._getLineIndentation("\tOneTab"))
	
Function test_coverageReporter_textFormat($t : cs:C1710.Testing)
	// Test text report generation
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Add some coverage data
	$tracker.recordLine("TestMethod"; 1)
	$tracker.recordLine("TestMethod"; 2)
	$tracker.collectData()
	
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	var $reporter : cs:C1710.CoverageReporter
	$reporter:=cs:C1710.CoverageReporter.new($tracker; $instrumenter)
	
	var $report : Text
	$report:=$reporter.generateReport("text")
	
	$t.assert.isTrue(Length:C16($report)>0)
	$t.assert.isTrue(Position:C15("Code Coverage Report"; $report)>0)
	$t.assert.isTrue(Position:C15("Overall Coverage"; $report)>0)
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageReporter_jsonFormat($t : cs:C1710.Testing)
	// Test JSON report generation
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Add some coverage data
	$tracker.recordLine("TestMethod"; 1)
	$tracker.collectData()
	
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	var $reporter : cs:C1710.CoverageReporter
	$reporter:=cs:C1710.CoverageReporter.new($tracker; $instrumenter)
	
	var $report : Text
	$report:=$reporter.generateReport("json")
	
	$t.assert.isTrue(Length:C16($report)>0)
	
	var $reportObj : Object
	$reportObj:=JSON Parse:C1218($report)
	
	$t.assert.isNotNull($reportObj.summary)
	$t.assert.isNotNull($reportObj.methods)
	$t.assert.areEqual("json"; $reportObj.format)
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageReporter_lcovFormat($t : cs:C1710.Testing)
	// Test lcov report generation
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Add some coverage data
	$tracker.recordLine("TestMethod"; 1)
	$tracker.recordLine("TestMethod"; 2)
	$tracker.collectData()
	
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	var $reporter : cs:C1710.CoverageReporter
	$reporter:=cs:C1710.CoverageReporter.new($tracker; $instrumenter)
	
	var $report : Text
	$report:=$reporter.generateReport("lcov")
	
	$t.assert.isTrue(Length:C16($report)>0)
	$t.assert.isTrue(Position:C15("SF:"; $report)>0)  // Source file marker
	$t.assert.isTrue(Position:C15("DA:"; $report)>0)  // Line data marker
	$t.assert.isTrue(Position:C15("end_of_record"; $report)>0)
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageReporter_htmlFormat($t : cs:C1710.Testing)
	// Test HTML report generation
	var $tracker : cs:C1710.CoverageTracker
	$tracker:=cs:C1710.CoverageTracker.new()
	$tracker.initialize()
	
	// Add some coverage data
	$tracker.recordLine("TestMethod"; 1)
	$tracker.collectData()
	
	var $instrumenter : cs:C1710.CodeInstrumenter
	$instrumenter:=cs:C1710.CodeInstrumenter.new(Storage:C1525)
	
	var $reporter : cs:C1710.CoverageReporter
	$reporter:=cs:C1710.CoverageReporter.new($tracker; $instrumenter)
	
	var $report : Text
	$report:=$reporter.generateReport("html")
	
	$t.assert.isTrue(Length:C16($report)>0)
	$t.assert.isTrue(Position:C15("<!DOCTYPE html>"; $report)>0)
	$t.assert.isTrue(Position:C15("Code Coverage Report"; $report)>0)
	$t.assert.isTrue(Position:C15("<style>"; $report)>0)
	
	// Cleanup
	$tracker.cleanup()
	
Function test_coverageTracker_mergeData($t : cs:C1710.Testing)
	// Test merging coverage data from multiple trackers
	var $tracker1 : cs:C1710.CoverageTracker
	$tracker1:=cs:C1710.CoverageTracker.new()
	$tracker1.initialize()
	$tracker1.recordLine("Method1"; 1)
	$tracker1.recordLine("Method1"; 2)
	$tracker1.collectData()
	
	var $tracker2 : cs:C1710.CoverageTracker
	$tracker2:=cs:C1710.CoverageTracker.new()
	$tracker2.initialize()
	$tracker2.recordLine("Method1"; 2)  // Overlapping line
	$tracker2.recordLine("Method2"; 1)
	$tracker2.collectData()
	
	// Merge tracker2 into tracker1
	$tracker1.mergeData($tracker2)
	
	var $method1Coverage : Object
	$method1Coverage:=$tracker1.getMethodCoverage("Method1")
	
	$t.assert.areEqual(1; Num:C11($method1Coverage["1"]))  // From tracker1
	$t.assert.areEqual(2; Num:C11($method1Coverage["2"]))  // 1 from tracker1 + 1 from tracker2
	
	var $method2Coverage : Object
	$method2Coverage:=$tracker1.getMethodCoverage("Method2")
	$t.assert.areEqual(1; Num:C11($method2Coverage["1"]))  // From tracker2
	
	// Cleanup
	$tracker1.cleanup()
	$tracker2.cleanup()
