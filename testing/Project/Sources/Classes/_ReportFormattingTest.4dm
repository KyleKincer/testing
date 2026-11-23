// Report formatting: failure formatters, JUnit failure XML, human report and Final Result block
// Built on synthetic result objects; nothing here fails on purpose
// #tags: unit

Class constructor()

// MARK: - Fixtures

Function _runner($params : Object) : cs.TestRunner
	var $runnerParams : Object
	$runnerParams:=($params#Null) ? $params : New object("format"; "human")
	return cs.TestRunner.new(Null; Null; $runnerParams)

Function _sampleError() : Object
	return New object(\
		"code"; -10503; \
		"text"; "W_Audit_Insert"; \
		"method"; "$rec.save()"; \
		"line"; 12; \
		"message"; "Record locked"; \
		"processNumber"; 7; \
		"context"; "local"; \
		"isLocal"; True; \
		"callChainJSON"; JSON Stringify([New object("name"; "W_Audit_Insert"; "type"; "projectMethod"; "line"; 12; "database"; "Symphony")]))

Function _assertionFailureTest() : Object
	return New object(\
		"name"; "test_assert"; \
		"suite"; "_ExampleTest"; \
		"passed"; False; \
		"failed"; True; \
		"skipped"; False; \
		"duration"; 1; \
		"runtimeErrors"; []; \
		"logMessages"; ["crosses the date boundary"]; \
		"assertions"; [New object("passed"; False; "expected"; 2; "actual"; 1; "message"; "crosses the date boundary"; "line"; 42)]; \
		"assertionCount"; 1; \
		"callChain"; Null)

Function _runtimeErrorTest() : Object
	var $error : Object
	$error:=This._sampleError()
	return New object(\
		"name"; "test_runtime"; \
		"suite"; "_ExampleTest"; \
		"passed"; False; \
		"failed"; True; \
		"skipped"; False; \
		"duration"; 2; \
		"runtimeErrors"; [$error]; \
		"logMessages"; []; \
		"assertions"; [New object("passed"; False; "expected"; Null; "actual"; "[-10503] Record locked"; "message"; "Runtime error: Record locked"; "line"; 12; "isRuntimeError"; True)]; \
		"assertionCount"; 1; \
		"callChain"; Null)

Function _passingTest($name : Text) : Object
	return New object(\
		"name"; $name; \
		"suite"; "_ExampleTest"; \
		"passed"; True; \
		"failed"; False; \
		"skipped"; False; \
		"duration"; 0; \
		"runtimeErrors"; []; \
		"logMessages"; []; \
		"assertions"; [New object("passed"; True; "expected"; True; "actual"; True; "message"; "ok")]; \
		"assertionCount"; 1)

Function _skippedTest() : Object
	return New object(\
		"name"; "test_skipped"; \
		"suite"; "_ExampleTest"; \
		"passed"; False; \
		"failed"; False; \
		"skipped"; True; \
		"duration"; 0; \
		"runtimeErrors"; []; \
		"logMessages"; []; \
		"assertions"; []; \
		"assertionCount"; 0)

Function _loadResults($runner : cs.TestRunner; $tests : Collection)
	var $suite : Object
	$suite:=New object("name"; "_ExampleTest"; "tests"; $tests; "passed"; 0; "failed"; 0; "skipped"; 0; "assertions"; 0)
	
	$runner._initializeResults()
	var $test : Object
	For each ($test; $tests)
		$runner.results.totalTests+=1
		$runner.results.assertions+=$test.assertionCount
		$suite.assertions+=$test.assertionCount
		Case of 
			: ($test.skipped)
				$runner.results.skipped+=1
				$suite.skipped+=1
			: ($test.passed)
				$runner.results.passed+=1
				$suite.passed+=1
			Else 
				$runner.results.failed+=1
				$suite.failed+=1
				$runner.results.failedTests.push($test)
		End case 
	End for each 
	$runner.results.suites.push($suite)
	$runner.results.duration:=1234

Function _redRunner($params : Object) : cs.TestRunner
	var $runner : cs.TestRunner
	$runner:=This._runner($params)
	This._loadResults($runner; [This._assertionFailureTest(); This._runtimeErrorTest(); This._passingTest("test_pass")])
	return $runner

Function _greenRunner() : cs.TestRunner
	var $runner : cs.TestRunner
	$runner:=This._runner()
	This._loadResults($runner; [This._passingTest("test_a"); This._passingTest("test_b"); This._skippedTest()])
	return $runner

Function _addGlobalError($runner : cs.TestRunner)
	var $globalError : Object
	$globalError:=This._sampleError()
	$globalError.context:="global"
	$globalError.isLocal:=False
	$runner.results.globalErrors:=[$globalError]
	$runner.results.globalErrorCount:=1
	$runner.results.hasGlobalErrors:=True

Function _indexOfPrefix($lines : Collection; $prefix : Text) : Integer
	var $index : Integer
	For ($index; 0; $lines.length-1)
		If (Position($prefix; $lines[$index]; *)=1)
			return $index
		End if 
	End for 
	return -1

// MARK: - _formatRuntimeError

Function test_formatRuntimeError_fullRecord($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	$t.assert.areEqual($t; "Runtime error [-10503] Record locked — in W_Audit_Insert line 12 (formula: $rec.save())"; $runner._formatRuntimeError(This._sampleError()); "Full record should include code, message, method, line and formula")

Function test_formatRuntimeError_missingMessage($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $error : Object
	$error:=This._sampleError()
	OB REMOVE($error; "message")
	$error.method:=""
	$t.assert.areEqual($t; "Runtime error [-10503] — in W_Audit_Insert line 12"; $runner._formatRuntimeError($error); "Missing message should be omitted")

Function test_formatRuntimeError_missingLine($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $error : Object
	$error:=This._sampleError()
	OB REMOVE($error; "line")
	$error.method:=""
	$t.assert.areEqual($t; "Runtime error [-10503] Record locked — in W_Audit_Insert"; $runner._formatRuntimeError($error); "Missing line should be omitted")

Function test_formatRuntimeError_missingCode($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	$t.assert.areEqual($t; "Runtime error [?] boom — in M"; $runner._formatRuntimeError(New object("text"; "M"; "message"; "boom")); "Missing code should show ?")
	$t.assert.areEqual($t; "Runtime error [?] boom — in M"; $runner._formatRuntimeError(New object("code"; 0; "text"; "M"; "message"; "boom")); "Code 0 should show ? rather than [0]")

Function test_formatRuntimeError_formulaEmptyOrSameAsMethod($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $error : Object
	$error:=This._sampleError()
	
	$error.method:=""
	$t.assert.isTrue($t; Position("formula:"; $runner._formatRuntimeError($error))=0; "Empty formula should be omitted")
	
	$error.method:=$error.text
	$t.assert.isTrue($t; Position("formula:"; $runner._formatRuntimeError($error))=0; "Formula equal to method should be omitted")

Function test_formatGlobalError_reusesRuntimeFormatter($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	$t.assert.areEqual($t; "- Process 7: "+$runner._formatRuntimeError(This._sampleError()); $runner._formatGlobalErrorForLog(This._sampleError()); "Global error line should wrap the runtime-error formatter")

// MARK: - _formatAssertionFailure

Function test_formatAssertionFailure_withLine($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	$t.assert.areEqual($t; "Assertion failed at line 42: crosses the date boundary (expected: 2, actual: 1)"; $runner._formatAssertionFailure(This._assertionFailureTest().assertions[0]); "Should include line, message, expected and actual")

Function test_formatAssertionFailure_withoutLineTextValues($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $assertion : Object
	$assertion:=New object("passed"; False; "expected"; "a"; "actual"; "b"; "message"; "strings differ")
	$t.assert.areEqual($t; "Assertion failed: strings differ (expected: \"a\", actual: \"b\")"; $runner._formatAssertionFailure($assertion); "Text values should be quoted; no line when absent")

Function test_formatAssertionFailure_nullValue($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $assertion : Object
	$assertion:=New object("passed"; False; "expected"; Null; "actual"; 5; "message"; "should be null"; "line"; 3)
	$t.assert.areEqual($t; "Assertion failed at line 3: should be null (expected: Null, actual: 5)"; $runner._formatAssertionFailure($assertion); "Null should render as Null")

Function test_formatAssertionFailure_stripsDefaultPrefix($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $assertion : Object
	$assertion:=New object("passed"; False; "expected"; True; "actual"; False; "message"; "Assertion failed: value is not true")
	$t.assert.areEqual($t; "Assertion failed: value is not true (expected: True, actual: False)"; $runner._formatAssertionFailure($assertion); "Default assert message should not repeat 'Assertion failed'")

// MARK: - _describeFailure

Function test_describeFailure_runtimeErrorOnly($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $reasons : Collection
	$reasons:=$runner._describeFailure(This._runtimeErrorTest())
	$t.assert.areEqual($t; 1; $reasons.length; "Synthetic runtime-error assertion should not be reported twice")
	$t.assert.areEqual($t; $runner._formatRuntimeError(This._sampleError()); $reasons[0]; "Reason should be the formatted runtime error")

Function test_describeFailure_assertionsOnly($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $test : Object
	$test:=This._assertionFailureTest()
	$test.assertions.push(New object("passed"; True; "expected"; 1; "actual"; 1; "message"; "passing"))
	var $reasons : Collection
	$reasons:=$runner._describeFailure($test)
	$t.assert.areEqual($t; 1; $reasons.length; "Only failed assertions should be listed")
	$t.assert.areEqual($t; "Assertion failed at line 42: crosses the date boundary (expected: 2, actual: 1)"; $reasons[0]; "Reason should be the formatted assertion")

Function test_describeFailure_runtimeErrorsFirst($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $test : Object
	$test:=This._runtimeErrorTest()
	$test.assertions.unshift(This._assertionFailureTest().assertions[0])
	var $reasons : Collection
	$reasons:=$runner._describeFailure($test)
	$t.assert.areEqual($t; 2; $reasons.length; "Runtime error and assertion should both be listed")
	$t.assert.isTrue($t; Position("Runtime error ["; $reasons[0]; *)=1; "Runtime error should come first")
	$t.assert.isTrue($t; Position("Assertion failed"; $reasons[1]; *)=1; "Assertion should come second")

Function test_describeFailure_logMessagesFallback($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $test : Object
	$test:=New object("name"; "x"; "suite"; "S"; "runtimeErrors"; []; "assertions"; []; "logMessages"; ["custom reason"])
	var $reasons : Collection
	$reasons:=$runner._describeFailure($test)
	$t.assert.areEqual($t; 1; $reasons.length; "Should fall back to one log message")
	$t.assert.areEqual($t; "custom reason"; $reasons[0]; "Should use the first log message")

Function test_describeFailure_nothingKnown($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $reasons : Collection
	$reasons:=$runner._describeFailure(New object("name"; "x"; "suite"; "S"))
	$t.assert.areEqual($t; 1; $reasons.length; "Should produce one reason")
	$t.assert.areEqual($t; "Test failed"; $reasons[0]; "Should fall back to 'Test failed'")

// MARK: - JUnit

Function test_buildFailureXML_runtimeError($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $xml : Text
	$xml:=$runner._buildFailureXML(This._runtimeErrorTest())
	$t.assert.isTrue($t; Position("<error type=\"RuntimeError\" message=\"[-10503] Record locked (W_Audit_Insert:12)\">"; $xml; *)>0; "Runtime error should be an <error> with code, message, method and line")
	$t.assert.isTrue($t; Position("Runtime error [-10503] Record locked — in W_Audit_Insert line 12"; $xml; *)>0; "Body should include the formatted error")
	$t.assert.isTrue($t; Position("Test: _ExampleTest.test_runtime"; $xml; *)>0; "Body should name the test")
	$t.assert.isTrue($t; Position("W_Audit_Insert (projectMethod) at line 12 in Symphony"; $xml; *)>0; "Body should include the error's call chain")
	$t.assert.isTrue($t; Position("Location:"; $xml; *)=0; "Location: label should be gone")

Function test_buildFailureXML_assertionFailure($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $xml : Text
	$xml:=$runner._buildFailureXML(This._assertionFailureTest())
	$t.assert.isTrue($t; Position("<failure type=\"AssertionFailure\" message=\"Assertion failed at line 42: crosses the date boundary (expected: 2, actual: 1)\">"; $xml; *)>0; "Assertion failure should be a typed <failure> with expected/actual")
	$t.assert.isTrue($t; Position("Test: _ExampleTest.test_assert"; $xml; *)>0; "Body should name the test")

Function test_buildFailureXML_escapesMessage($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $test : Object
	$test:=This._assertionFailureTest()
	$test.assertions[0].message:="say \"hi\" <b> & ]]> done"
	var $xml : Text
	$xml:=$runner._buildFailureXML($test)
	$t.assert.isTrue($t; Position("say &quot;hi&quot; &lt;b&gt; &amp; ]]&gt; done"; $xml; *)>0; "Attribute should escape quotes, angle brackets and ampersands")
	$t.assert.isTrue($t; Position("]]]]><![CDATA[>"; $xml; *)>0; "CDATA terminator inside the body should be split")

Function test_terseFailure_structuredFields($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner()
	var $failure : Object
	$failure:=$runner._buildTerseFailure(This._runtimeErrorTest())
	$t.assert.areEqual($t; $runner._formatRuntimeError(This._sampleError()); $failure.error; "error should be the formatted runtime error")
	$t.assert.areEqual($t; -10503; $failure.errorCode; "errorCode should be set")
	$t.assert.areEqual($t; "W_Audit_Insert"; $failure.errorMethod; "errorMethod should be set")
	$t.assert.areEqual($t; 12; $failure.errorLine; "errorLine should be set")

// MARK: - Human report

Function test_humanReport_sectionOrder($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._redRunner()
	This._addGlobalError($runner)
	var $lines : Collection
	$lines:=$runner._buildHumanReportLines()
	
	var $summary; $failed; $runtime; $external; $final : Integer
	$summary:=$lines.indexOf("=== Test Results Summary ===")
	$failed:=$lines.indexOf("=== Failed Tests ===")
	$runtime:=$lines.indexOf("=== Runtime Errors (1) ===")
	$external:=$lines.indexOf("=== Runtime Errors Outside Test Processes (1) ===")
	$final:=$lines.indexOf("=== Final Result ===")
	
	$t.assert.isTrue($t; $failed>=0; "Failed Tests section should be present")
	$t.assert.isTrue($t; $runtime>$failed; "Runtime Errors should follow Failed Tests")
	$t.assert.isTrue($t; $external>$runtime; "External errors should follow Runtime Errors")
	$t.assert.isTrue($t; $summary>$external; "Summary should follow the failure details")
	$t.assert.isTrue($t; $final>$summary; "Final Result should follow Summary")
	$t.assert.isTrue($t; Position("RESULT: "; $lines[$lines.length-2]; *)=1; "RESULT line should come right before the verdict")

Function test_humanReport_failedTestsQualified($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._redRunner()
	var $lines : Collection
	$lines:=$runner._buildHumanReportLines()
	var $index : Integer
	$index:=$lines.indexOf("✗ _ExampleTest.test_assert")
	$t.assert.isTrue($t; $index>0; "Failed test should be listed as <suite>.<name>")
	$t.assert.areEqual($t; "    Assertion failed at line 42: crosses the date boundary (expected: 2, actual: 1)"; $lines[$index+1]; "Reason should follow the test name")
Function test_humanReport_runtimeSectionHasCallStack($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._redRunner()
	var $lines : Collection
	$lines:=$runner._buildHumanReportLines()
	var $start : Integer
	$start:=$lines.indexOf("=== Runtime Errors (1) ===")
	$t.assert.isTrue($t; $start>0; "Runtime Errors section should be present")
	$t.assert.areEqual($t; "✗ _ExampleTest.test_runtime"; $lines[$start+1]; "Section should name the test")
	$t.assert.areEqual($t; "    Call Stack:"; $lines[$start+3]; "Section should include the call stack")
	$t.assert.areEqual($t; "      1. W_Audit_Insert (projectMethod) at line 12 in Symphony"; $lines[$start+4]; "Call stack should come from callChainJSON")

Function test_humanReport_passRateHasPercent($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._redRunner()
	var $lines : Collection
	$lines:=$runner._buildHumanReportLines()
	var $index : Integer
	$index:=This._indexOfPrefix($lines; "Pass Rate: ")
	$t.assert.isTrue($t; $index>0; "Pass Rate line should be present")
	$t.assert.areEqual($t; "%"; Substring($lines[$index]; Length($lines[$index])); "Pass Rate should end with %")

// MARK: - Final Result block

Function test_finalResult_splitMatchesJUnitErrorCount($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._redRunner()
	var $lines : Collection
	$lines:=$runner._buildFinalResultLines()
	$t.assert.areEqual($t; 1; $runner._countTestsWithRuntimeErrors(); "Fixture should have one test with a runtime error")
	$t.assert.isTrue($t; $lines.indexOf("Failed:    1     (assertion failures)")>=0; "Failed should count assertion failures only")
	$t.assert.isTrue($t; $lines.indexOf("Errors:    1     (runtime errors in tests)")>=0; "Errors should match _countTestsWithRuntimeErrors")
	$t.assert.isTrue($t; $lines.indexOf("Duration:  1.2s")>=0; "Duration should be in seconds")

Function test_finalResult_redListsEveryFailedTest($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._redRunner()
	var $lines : Collection
	$lines:=$runner._buildFinalResultLines()
	var $failIndex; $errorIndex : Integer
	$failIndex:=$lines.indexOf("  FAIL   _ExampleTest.test_assert")
	$errorIndex:=$lines.indexOf("  ERROR  _ExampleTest.test_runtime")
	$t.assert.isTrue($t; $lines.indexOf("Failed / errored tests:")>=0; "Red run should have the failed list")
	$t.assert.isTrue($t; $failIndex>0; "Assertion failure should be listed with FAIL")
	$t.assert.isTrue($t; $errorIndex>0; "Runtime error should be listed with ERROR")
	$t.assert.areEqual($t; "         Assertion failed at line 42: crosses the date boundary (expected: 2, actual: 1)"; $lines[$failIndex+1]; "FAIL entry should have one reason line")
	$t.assert.areEqual($t; "         "+$runner._formatRuntimeError(This._sampleError()); $lines[$errorIndex+1]; "ERROR entry should have one reason line")
	$t.assert.areEqual($t; "RESULT: FAIL (1 failed, 1 error, 0 external)"; $lines[$lines.length-2]; "RESULT line should summarize the failure")
	$t.assert.areEqual($t; "❌ 1 test failed, ⚠️ 1 error"; $lines[$lines.length-1]; "Verdict should be the last line")

Function test_finalResult_greenRun($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._greenRunner()
	var $lines : Collection
	$lines:=$runner._buildFinalResultLines()
	$t.assert.areEqual($t; "RESULT: PASS (2 passed, 1 skipped)"; $lines[$lines.length-2]; "Green run should print RESULT: PASS")
	$t.assert.areEqual($t; "All tests passed! 🎉"; $lines[$lines.length-1]; "Green run should end with All tests passed")
	$t.assert.areEqual($t; -1; $lines.indexOf("Failed / errored tests:"); "Green run should have no failed list")
	$t.assert.isTrue($t; $lines.indexOf("Skipped:   1")>=0; "Skipped count should be shown")

Function test_finalResult_externalOnlyFails($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._greenRunner()
	This._addGlobalError($runner)
	var $lines : Collection
	$lines:=$runner._buildFinalResultLines()
	$t.assert.areEqual($t; "RESULT: FAIL (0 failed, 0 errors, 1 external)"; $lines[$lines.length-2]; "External errors alone should fail the run")
	$t.assert.areEqual($t; "⚠️ 1 external error"; $lines[$lines.length-1]; "External-only verdict should use the warning sign")
	$t.assert.isTrue($t; $lines.indexOf("External:  1     (runtime errors outside test processes)")>=0; "External count should be shown")

// MARK: - Output flags

Function test_consoleReport_byFormat($t : cs.Testing)
	$t.assert.isTrue($t; This._runner(New object("format"; "human")).consoleReport; "human should print the console report")
	$t.assert.isTrue($t; This._runner(New object("format"; "junit")).consoleReport; "junit should print the console report")
	$t.assert.isFalse($t; This._runner(New object("format"; "json")).consoleReport; "json should keep stdout clean")

Function test_quietAndDebug_parsing($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner(New object("format"; "human"; "quiet"; ""; "debug"; ""))
	$t.assert.isFalse($t; $runner.quietOutput; "quiet should be off unless quiet=true")
	$t.assert.isFalse($t; $runner.debugOutput; "debug should be off unless debug=true")
	
	$runner:=This._runner(New object("format"; "human"; "quiet"; "true"; "debug"; "true"))
	$t.assert.isTrue($t; $runner.quietOutput; "quiet=true should enable quiet output")
	$t.assert.isTrue($t; $runner.debugOutput; "debug=true should enable debug output")

Function test_quiet_doesNotChangeReportLines($t : cs.Testing)
	var $loud; $quiet : cs.TestRunner
	$loud:=This._redRunner(New object("format"; "human"; "quiet"; ""))
	$quiet:=This._redRunner(New object("format"; "human"; "quiet"; "true"))
	$t.assert.areEqual($t; JSON Stringify($loud._buildHumanReportLines()); JSON Stringify($quiet._buildHumanReportLines()); "quiet should only affect live lines")

Function test_quietSuiteLines_passingClassIsOneLine($t : cs.Testing)
	var $lines : Collection
	$lines:=This._runner()._buildQuietSuiteLines("_ExampleTest"; [This._passingTest("test_a"); This._passingTest("test_b"); This._skippedTest()])
	$t.assert.areEqual($t; 1; $lines.length; "A passing class should print a single line")
	$t.assert.areEqual($t; "✓ _ExampleTest (2 passed, 1 skipped)"; $lines[0]; "Class line should show the counts")

Function test_quietSuiteLines_failingClassListsFailedTests($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner(New object("format"; "human"; "verbose"; ""))
	var $lines : Collection
	$lines:=$runner._buildQuietSuiteLines("_ExampleTest"; [This._passingTest("test_a"); This._runtimeErrorTest()])
	$t.assert.areEqual($t; "✗ _ExampleTest (1 failed, 1 passed)"; $lines[0]; "Failing class line should show the counts")
	$t.assert.areEqual($t; "  ✗ _ExampleTest.test_runtime (2ms)"; $lines[1]; "Failed test should be listed under its class")
	$t.assert.areEqual($t; "      "+$runner._formatRuntimeError(This._sampleError()); $lines[2]; "Failed test should keep its reason")
	$t.assert.areEqual($t; 3; $lines.length; "Passing tests should not be listed")

Function test_liveFailureLines_includeSuiteAndReason($t : cs.Testing)
	var $runner : cs.TestRunner
	$runner:=This._runner(New object("format"; "human"; "verbose"; ""))
	var $lines : Collection
	$lines:=$runner._buildLiveFailureLines(This._runtimeErrorTest())
	$t.assert.areEqual($t; "  ✗ _ExampleTest.test_runtime (2ms)"; $lines[0]; "Live line should include suite and test name")
	$t.assert.areEqual($t; "      "+$runner._formatRuntimeError(This._sampleError()); $lines[1]; "Live line should be followed by the formatted reason")

// MARK: - Assertion line lookup

Function _lineContext() : Object
	return New object("testClassName"; "_ExampleTest"; "testFunctionName"; "test_assert")

Function test_findTestLine_classQualifiedFrame($t : cs.Testing)
	var $chain : Collection
	$chain:=[\
		New object("name"; "Assert.areEqual"; "line"; 30); \
		New object("name"; "_ExampleTest.test_assert"; "line"; 7)]
	$t.assert.areEqual($t; 7; cs.Assert.new()._findTestLine(This._lineContext(); $chain); "Class function frames are named <Class>.<function>")

Function test_findTestLine_bareFrame($t : cs.Testing)
	var $chain : Collection
	$chain:=[New object("name"; "test_assert"; "line"; 9)]
	$t.assert.areEqual($t; 9; cs.Assert.new()._findTestLine(This._lineContext(); $chain); "A bare function-name frame should still match")

Function test_findTestLine_otherClassIgnored($t : cs.Testing)
	var $chain : Collection
	$chain:=[New object("name"; "_OtherTest.test_assert"; "line"; 11)]
	$t.assert.areEqual($t; 0; cs.Assert.new()._findTestLine(This._lineContext(); $chain); "A same-named function on another class should not match")
