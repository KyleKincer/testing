// Generates coverage reports in various formats

property tracker : cs.CoverageTracker
property instrumenter : cs.CodeInstrumenter
property totalLines : Integer
property coveredLines : Integer
property coveragePercent : Real

Class constructor($tracker : cs.CoverageTracker; $instrumenter : cs.CodeInstrumenter)
	This.tracker:=$tracker
	This.instrumenter:=$instrumenter
	This.totalLines:=0
	This.coveredLines:=0
	This.coveragePercent:=0
	
Function calculateCoverage() : Object
	// Calculate detailed coverage statistics
	
	var $results : Object
	$results:=This.tracker.collectResults()
	
	var $methodStats : Collection
	$methodStats:=New collection
	
	var $totalLines : Integer
	var $coveredLines : Integer
	$totalLines:=0
	$coveredLines:=0
	
	var $methodPath : Text
	For each ($methodPath; This.instrumenter.instrumentedMethods)
		var $methodCoverage : Object
		$methodCoverage:=This._calculateMethodCoverage($methodPath)
		
		$methodStats.push($methodCoverage)
		$totalLines+=$methodCoverage.totalLines
		$coveredLines+=$methodCoverage.coveredLines
	End for each 
	
	This.totalLines:=$totalLines
	This.coveredLines:=$coveredLines
	This.coveragePercent:=($totalLines>0) ? Round(($coveredLines/$totalLines)*100; 2) : 0
	
	var $report : Object
	$report:=New object(\
		"summary"; New object(\
		"totalLines"; $totalLines; \
		"coveredLines"; $coveredLines; \
		"uncoveredLines"; $totalLines-$coveredLines; \
		"coveragePercent"; This.coveragePercent\
		); \
		"methods"; $methodStats\
		)
	
	return $report
	
Function _calculateMethodCoverage($methodPath : Text) : Object
	// Calculate coverage for a single method
	
	var $originalCode : Text
	$originalCode:=This.instrumenter.originalCode[$methodPath]
	
	If ($originalCode="")
		return New object(\
			"method"; $methodPath; \
			"totalLines"; 0; \
			"coveredLines"; 0; \
			"coveragePercent"; 0; \
			"coveredLineNumbers"; New collection\
			)
	End if 
	
	// Count executable lines in original code
	var $lines : Collection
	$lines:=Split string($originalCode; "\r\n")
	
	var $executableLines : Collection
	$executableLines:=New collection
	
	var $lineNum : Integer
	var $line : Text
	
	For ($lineNum; 0; $lines.length-1)
		$line:=$lines[$lineNum]
		If (This._isExecutableLine($line))
			$executableLines.push($lineNum+1)  // 1-based line numbers
		End if 
	End for 
	
	// Get covered lines
	var $coveredLines : Collection
	$coveredLines:=This.tracker.getCoverageForMethod($methodPath)
	
	// Calculate coverage
	var $totalLines : Integer
	var $coveredCount : Integer
	var $coveragePercent : Real
	
	$totalLines:=$executableLines.length
	$coveredCount:=$coveredLines.length
	$coveragePercent:=($totalLines>0) ? Round(($coveredCount/$totalLines)*100; 2) : 0
	
	return New object(\
		"method"; $methodPath; \
		"totalLines"; $totalLines; \
		"coveredLines"; $coveredCount; \
		"uncoveredLines"; $totalLines-$coveredCount; \
		"coveragePercent"; $coveragePercent; \
		"coveredLineNumbers"; $coveredLines; \
		"executableLines"; $executableLines\
		)
	
Function generateTextReport() : Text
	// Generate human-readable text report
	
	var $report : Object
	$report:=This.calculateCoverage()
	
	var $output : Text
	$output:=""
	
	$output:=$output+"\r\n"
	$output:=$output+"=== Code Coverage Report ===\r\n"
	$output:=$output+"\r\n"
	
	$output:=$output+"Overall Coverage: "+String($report.summary.coveragePercent)+"% "
	$output:=$output+"("+String($report.summary.coveredLines)+"/"+String($report.summary.totalLines)+" lines)\r\n"
	$output:=$output+"\r\n"
	
	$output:=$output+"Method Coverage:\r\n"
	
	var $method : Object
	For each ($method; $report.methods)
		$output:=$output+"  "+$method.method+": "+String($method.coveragePercent)+"% "
		$output:=$output+"("+String($method.coveredLines)+"/"+String($method.totalLines)+" lines)\r\n"
		
		// Show uncovered lines if any
		If ($method.uncoveredLines>0)
			var $uncoveredLines : Collection
			$uncoveredLines:=This._getUncoveredLines($method.executableLines; $method.coveredLineNumbers)
			If ($uncoveredLines.length>0)
				$output:=$output+"    Uncovered lines: "+$uncoveredLines.join(", ")+"\r\n"
			End if 
		End if 
	End for each 
	
	$output:=$output+"\r\n"
	
	return $output
	
Function generateJSONReport() : Text
	// Generate JSON coverage report
	
	var $report : Object
	$report:=This.calculateCoverage()
	
	return JSON Stringify($report; *)
	
Function generateLCOVReport() : Text
	// Generate LCOV format report (compatible with many CI/CD tools)
	
	var $report : Object
	$report:=This.calculateCoverage()
	
	var $output : Text
	$output:=""
	
	var $method : Object
	For each ($method; $report.methods)
		// Convert method path to file path
		var $filePath : Text
		$filePath:=This._methodPathToFilePath($method.method)
		
		$output:=$output+"TN:\r\n"  // Test name (empty)
		$output:=$output+"SF:"+$filePath+"\r\n"  // Source file
		
		// Line coverage data
		var $lineNum : Integer
		For each ($lineNum; $method.executableLines)
			var $hit : Integer
			$hit:=($method.coveredLineNumbers.indexOf($lineNum)#-1) ? 1 : 0
			$output:=$output+"DA:"+String($lineNum)+","+String($hit)+"\r\n"
		End for each 
		
		// Summary
		$output:=$output+"LF:"+String($method.totalLines)+"\r\n"  // Lines found
		$output:=$output+"LH:"+String($method.coveredLines)+"\r\n"  // Lines hit
		$output:=$output+"end_of_record\r\n"
	End for each 
	
	return $output
	
Function writeReportToFile($format : Text; $outputPath : Text)
	// Write coverage report to file
	
	var $content : Text
	
	Case of 
		: ($format="text")
			$content:=This.generateTextReport()
		: ($format="json")
			$content:=This.generateJSONReport()
		: ($format="lcov")
			$content:=This.generateLCOVReport()
		Else 
			$content:=This.generateTextReport()
	End case 
	
	// Parse path and create folder if needed
	var $pathParts : Collection
	$pathParts:=Split string($outputPath; "/")
	
	var $outputFolder : 4D.Folder
	If ($pathParts.length>1)
		var $folderPath : Text
		$folderPath:=$pathParts.slice(0; $pathParts.length-1).join("/")
		$outputFolder:=Folder(fk database folder; *).folder($folderPath)
	Else 
		$outputFolder:=Folder(fk database folder; *)
	End if 
	
	If (Not($outputFolder.exists))
		$outputFolder.create()
	End if 
	
	var $filename : Text
	$filename:=$pathParts[$pathParts.length-1]
	
	var $file : 4D.File
	$file:=$outputFolder.file($filename)
	$file.setText($content; "UTF-8")
	
	LOG EVENT(Into system standard outputs; "Coverage report written to: "+$file.platformPath+"\r\n"; Information message)
	
Function logToConsole()
	// Log coverage report to console
	
	var $report : Text
	$report:=This.generateTextReport()
	
	LOG EVENT(Into system standard outputs; $report; Information message)
	
Function _getUncoveredLines($executableLines : Collection; $coveredLines : Collection) : Collection
	// Get list of uncovered line numbers
	
	var $uncovered : Collection
	$uncovered:=New collection
	
	var $lineNum : Integer
	For each ($lineNum; $executableLines)
		If ($coveredLines.indexOf($lineNum)=-1)
			$uncovered.push($lineNum)
		End if 
	End for each 
	
	return $uncovered
	
Function _methodPathToFilePath($methodPath : Text) : Text
	// Convert method path to file path
	// e.g., "MyClass.myMethod" -> "testing/Project/Sources/Classes/MyClass.4dm"
	
	var $parts : Collection
	$parts:=Split string($methodPath; ".")
	
	If ($parts.length>1)
		// Class method
		return "testing/Project/Sources/Classes/"+$parts[0]+".4dm"
	Else 
		// Project method
		return "testing/Project/Sources/Methods/"+$methodPath+".4dm"
	End if 
	
Function _isExecutableLine($line : Text) : Boolean
	// Determine if a line is executable (duplicated from CodeInstrumenter for independence)
	
	var $trimmed : Text
	$trimmed:=This._trim($line)
	
	If ($trimmed="")
		return False
	End if 
	
	If (($trimmed="//@@") || ($trimmed="//@"))
		return False
	End if 
	
	If ($trimmed="property @")
		return False
	End if 
	
	If ($trimmed="Class constructor@")
		return False
	End if 
	
	If ($trimmed="Function @")
		return False
	End if 
	
	If (($trimmed="End @") || ($trimmed="End if") || ($trimmed="End case") || ($trimmed="End for") || ($trimmed="End while") || ($trimmed="End use"))
		return False
	End if 
	
	If (($trimmed="Else") || ($trimmed="Else @") || ($trimmed=": @"))
		return False
	End if 
	
	return True
	
Function _trim($text : Text) : Text
	// Remove leading and trailing whitespace
	
	var $result : Text
	$result:=$text
	
	While (($result#"") && (($result[[1]]=" ") || ($result[[1]]="\t")))
		$result:=Substring($result; 2)
	End while 
	
	While (($result#"") && (($result[[Length($result)]]=" ") || ($result[[Length($result)]]="\t")))
		$result:=Substring($result; 1; Length($result)-1)
	End while 
	
	return $result
