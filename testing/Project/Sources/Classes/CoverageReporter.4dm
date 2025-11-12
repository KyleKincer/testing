// Generates coverage reports in various formats
// Supports text, JSON, HTML, and lcov formats

property coverageTracker : cs.CoverageTracker
property instrumenter : cs.CodeInstrumenter
property outputFormat : Text  // "text", "json", "html", "lcov"
property methodSourceCode : Object  // Map of method path -> source code for line-level reporting

Class constructor($tracker : cs.CoverageTracker; $instrumenter : cs.CodeInstrumenter)
	This.coverageTracker:=$tracker
	This.instrumenter:=$instrumenter
	This.outputFormat:="text"
	This.methodSourceCode:=New object
	
Function generateReport($format : Text) : Text
	// Generate coverage report in specified format
	This.outputFormat:=$format || "text"
	
	Case of 
		: (This.outputFormat="json")
			return This._generateJSONReport()
		: (This.outputFormat="html")
			return This._generateHTMLReport()
		: (This.outputFormat="lcov")
			return This._generateLcovReport()
		Else 
			return This._generateTextReport()
	End case 
	
Function writeReportToFile($format : Text; $outputPath : Text) : Boolean
	// Generate report and write to file
	var $report : Text
	$report:=This.generateReport($format)
	
	// Parse path
	var $pathParts : Collection
	$pathParts:=Split string($outputPath; "/")
	
	// Build folder path
	var $outputFolder : 4D.Folder
	If ($pathParts.length>1)
		var $folderPath : Text
		$folderPath:=$pathParts.slice(0; $pathParts.length-1).join("/")
		$outputFolder:=Folder(fk database folder; *).folder($folderPath)
	Else 
		$outputFolder:=Folder(fk database folder; *)
	End if 
	
	// Create folder if needed
	If (Not($outputFolder.exists))
		$outputFolder.create()
	End if 
	
	// Write file
	var $filename : Text
	$filename:=$pathParts[$pathParts.length-1]
	
	var $file : 4D.File
	$file:=$outputFolder.file($filename)
	$file.setText($report; "UTF-8")
	
	return $file.exists
	
Function _generateTextReport() : Text
	// Generate human-readable text report
	var $report : Text
	var $stats : Object
	
	$stats:=This.coverageTracker.getCoverageStats()
	
	$report:="=== Code Coverage Report ===\r\n"
	$report:=$report+"\r\n"
	$report:=$report+"Overall Coverage: "+String($stats.coveragePercent; "##0.00")+"%\r\n"
	$report:=$report+"Lines Covered: "+String($stats.coveredLines)+" / "+String($stats.totalLines)+"\r\n"
	$report:=$report+"Methods Tracked: "+String($stats.methodCount)+"\r\n"
	$report:=$report+"Duration: "+String($stats.duration)+"ms\r\n"
	$report:=$report+"\r\n"
	
	// Method-level details
	var $methodStats : Collection
	$methodStats:=This.coverageTracker.getDetailedStats()
	
	If ($methodStats.length>0)
		$report:=$report+"=== Method Coverage ===\r\n"
		$report:=$report+"\r\n"
		
		// Sort by coverage percentage (ascending to show worst coverage first)
		$methodStats:=$methodStats.orderBy("coveragePercent")
		
		var $method : Object
		For each ($method; $methodStats)
			var $coverageBar : Text
			$coverageBar:=This._createCoverageBar($method.coveragePercent)
			
			$report:=$report+$method.method+"\r\n"
			$report:=$report+"  "+$coverageBar+" "+String($method.coveragePercent; "##0.00")+"%"
			$report:=$report+" ("+String($method.coveredLines)+"/"+String($method.totalLines)+" lines)\r\n"
			
			// Show uncovered lines if coverage < 100%
			If ($method.coveragePercent<100)
				var $uncoveredLines : Collection
				$uncoveredLines:=This.coverageTracker.getUncoveredLines($method.method)
				
				If ($uncoveredLines.length>0)
					$report:=$report+"  Uncovered lines: "+This._formatLineNumbers($uncoveredLines)+"\r\n"
				End if 
			End if 
			
			$report:=$report+"\r\n"
		End for each 
	End if 
	
	return $report
	
Function _generateJSONReport() : Text
	// Generate JSON coverage report
	var $stats : Object
	$stats:=This.coverageTracker.getCoverageStats()
	
	var $methodStats : Collection
	$methodStats:=This.coverageTracker.getDetailedStats()
	
	var $report : Object
	$report:=New object(\
		"summary"; $stats; \
		"methods"; $methodStats; \
		"format"; "json"; \
		"version"; "1.0"\
		)
	
	// Add uncovered lines for each method
	var $method : Object
	For each ($method; $methodStats)
		$method.uncoveredLines:=This.coverageTracker.getUncoveredLines($method.method)
	End for each 
	
	return JSON Stringify($report; *)
	
Function _generateHTMLReport() : Text
	// Generate HTML coverage report
	var $html : Text
	var $stats : Object
	
	$stats:=This.coverageTracker.getCoverageStats()
	
	// HTML header
	$html:="<!DOCTYPE html>\r\n"
	$html:=$html+"<html>\r\n"
	$html:=$html+"<head>\r\n"
	$html:=$html+"<meta charset=\"UTF-8\">\r\n"
	$html:=$html+"<title>Code Coverage Report</title>\r\n"
	$html:=$html+"<style>\r\n"
	$html:=$html+This._getHTMLStyles()
	$html:=$html+"</style>\r\n"
	$html:=$html+"</head>\r\n"
	$html:=$html+"<body>\r\n"
	
	// Header
	$html:=$html+"<div class=\"header\">\r\n"
	$html:=$html+"<h1>Code Coverage Report</h1>\r\n"
	$html:=$html+"</div>\r\n"
	
	// Summary section
	$html:=$html+"<div class=\"summary\">\r\n"
	$html:=$html+"<h2>Summary</h2>\r\n"
	$html:=$html+"<div class=\"coverage-badge coverage-"+This._getCoverageLevel($stats.coveragePercent)+"\">\r\n"
	$html:=$html+String($stats.coveragePercent; "##0.00")+"%\r\n"
	$html:=$html+"</div>\r\n"
	$html:=$html+"<p>Lines Covered: "+String($stats.coveredLines)+" / "+String($stats.totalLines)+"</p>\r\n"
	$html:=$html+"<p>Methods Tracked: "+String($stats.methodCount)+"</p>\r\n"
	$html:=$html+"</div>\r\n"
	
	// Method details
	var $methodStats : Collection
	$methodStats:=This.coverageTracker.getDetailedStats()
	
	If ($methodStats.length>0)
		$methodStats:=$methodStats.orderBy("coveragePercent")
		
		$html:=$html+"<div class=\"methods\">\r\n"
		$html:=$html+"<h2>Method Coverage</h2>\r\n"
		$html:=$html+"<table>\r\n"
		$html:=$html+"<thead>\r\n"
		$html:=$html+"<tr><th>Method</th><th>Coverage</th><th>Lines</th><th>Uncovered Lines</th></tr>\r\n"
		$html:=$html+"</thead>\r\n"
		$html:=$html+"<tbody>\r\n"
		
		var $method : Object
		For each ($method; $methodStats)
			var $coverageLevel : Text
			$coverageLevel:=This._getCoverageLevel($method.coveragePercent)
			
			$html:=$html+"<tr class=\"coverage-"+$coverageLevel+"\">\r\n"
			$html:=$html+"<td>"+This._escapeHTML($method.method)+"</td>\r\n"
			$html:=$html+"<td><div class=\"progress-bar\"><div class=\"progress-fill\" style=\"width: "+String($method.coveragePercent; "##0.00")+"%\"></div></div>"
			$html:=$html+String($method.coveragePercent; "##0.00")+"%</td>\r\n"
			$html:=$html+"<td>"+String($method.coveredLines)+"/"+String($method.totalLines)+"</td>\r\n"
			
			var $uncoveredLines : Collection
			$uncoveredLines:=This.coverageTracker.getUncoveredLines($method.method)
			$html:=$html+"<td>"+This._formatLineNumbers($uncoveredLines)+"</td>\r\n"
			
			$html:=$html+"</tr>\r\n"
		End for each 
		
		$html:=$html+"</tbody>\r\n"
		$html:=$html+"</table>\r\n"
		$html:=$html+"</div>\r\n"
	End if 
	
	// Footer
	$html:=$html+"<div class=\"footer\">\r\n"
	$html:=$html+"<p>Generated by 4D Unit Testing Framework</p>\r\n"
	$html:=$html+"</div>\r\n"
	$html:=$html+"</body>\r\n"
	$html:=$html+"</html>\r\n"
	
	return $html
	
Function _generateLcovReport() : Text
	// Generate lcov format report (compatible with lcov tools and many CI systems)
	var $lcov : Text
	$lcov:=""
	
	var $methodStats : Collection
	$methodStats:=This.coverageTracker.getDetailedStats()
	
	var $method : Object
	For each ($method; $methodStats)
		// TN: Test name
		$lcov:=$lcov+"TN:\r\n"
		
		// SF: Source file
		$lcov:=$lcov+"SF:"+$method.method+"\r\n"
		
		// DA: Line coverage (line_number,execution_count)
		var $methodCoverage : Object
		$methodCoverage:=This.coverageTracker.getMethodCoverage($method.method)
		
		var $lineNum : Text
		For each ($lineNum; $methodCoverage)
			var $count : Integer
			$count:=Num($methodCoverage[$lineNum])
			$lcov:=$lcov+"DA:"+$lineNum+","+String($count)+"\r\n"
		End for each 
		
		// LF: Lines found
		$lcov:=$lcov+"LF:"+String($method.totalLines)+"\r\n"
		
		// LH: Lines hit
		$lcov:=$lcov+"LH:"+String($method.coveredLines)+"\r\n"
		
		// end_of_record
		$lcov:=$lcov+"end_of_record\r\n"
	End for each 
	
	return $lcov
	
Function _createCoverageBar($percent : Real) : Text
	// Create ASCII progress bar
	var $bar : Text
	var $filled : Integer
	var $barWidth : Integer
	
	$barWidth:=20
	$filled:=Round($percent*$barWidth/100; 0)
	
	$bar:="["
	
	var $i : Integer
	For ($i; 1; $barWidth)
		If ($i<=$filled)
			$bar:=$bar+"="
		Else 
			$bar:=$bar+" "
		End if 
	End for 
	
	$bar:=$bar+"]"
	
	return $bar
	
Function _formatLineNumbers($lineNumbers : Collection) : Text
	// Format line numbers for display (e.g., "1-5, 7, 9-11")
	If ($lineNumbers.length=0)
		return "none"
	End if 
	
	var $formatted : Text
	var $ranges : Collection
	$ranges:=[]
	
	var $start; $end : Integer
	$start:=$lineNumbers[0]
	$end:=$start
	
	var $i : Integer
	For ($i; 1; $lineNumbers.length-1)
		If ($lineNumbers[$i]=$end+1)
			$end:=$lineNumbers[$i]
		Else 
			// Save current range
			If ($start=$end)
				$ranges.push(String($start))
			Else 
				$ranges.push(String($start)+"-"+String($end))
			End if 
			
			$start:=$lineNumbers[$i]
			$end:=$start
		End if 
	End for 
	
	// Save final range
	If ($start=$end)
		$ranges.push(String($start))
	Else 
		$ranges.push(String($start)+"-"+String($end))
	End if 
	
	$formatted:=$ranges.join(", ")
	
	return $formatted
	
Function _getCoverageLevel($percent : Real) : Text
	// Get coverage level for styling
	Case of 
		: ($percent>=90)
			return "excellent"
		: ($percent>=75)
			return "good"
		: ($percent>=50)
			return "moderate"
		Else 
			return "poor"
	End case 
	
Function _escapeHTML($text : Text) : Text
	// Escape HTML special characters
	var $escaped : Text
	$escaped:=Replace string($text; "&"; "&amp;")
	$escaped:=Replace string($escaped; "<"; "&lt;")
	$escaped:=Replace string($escaped; ">"; "&gt;")
	$escaped:=Replace string($escaped; "\""; "&quot;")
	return $escaped
	
Function _getHTMLStyles() : Text
	// Return CSS styles for HTML report
	var $css : Text
	
	$css:="body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }\r\n"
	$css:=$css+".header { background: #2c3e50; color: white; padding: 20px; margin: -20px -20px 20px -20px; }\r\n"
	$css:=$css+".header h1 { margin: 0; }\r\n"
	$css:=$css+".summary { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\r\n"
	$css:=$css+".coverage-badge { display: inline-block; padding: 10px 20px; border-radius: 5px; font-size: 24px; font-weight: bold; margin: 10px 0; }\r\n"
	$css:=$css+".coverage-excellent { background: #27ae60; color: white; }\r\n"
	$css:=$css+".coverage-good { background: #f39c12; color: white; }\r\n"
	$css:=$css+".coverage-moderate { background: #e67e22; color: white; }\r\n"
	$css:=$css+".coverage-poor { background: #e74c3c; color: white; }\r\n"
	$css:=$css+".methods { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\r\n"
	$css:=$css+"table { width: 100%; border-collapse: collapse; }\r\n"
	$css:=$css+"thead { background: #34495e; color: white; }\r\n"
	$css:=$css+"th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }\r\n"
	$css:=$css+"tr.coverage-excellent { background: #d5f4e6; }\r\n"
	$css:=$css+"tr.coverage-good { background: #ffeaa7; }\r\n"
	$css:=$css+"tr.coverage-moderate { background: #fab1a0; }\r\n"
	$css:=$css+"tr.coverage-poor { background: #ffcccc; }\r\n"
	$css:=$css+".progress-bar { display: inline-block; width: 100px; height: 10px; background: #ecf0f1; border-radius: 5px; overflow: hidden; vertical-align: middle; margin-right: 10px; }\r\n"
	$css:=$css+".progress-fill { height: 100%; background: #3498db; }\r\n"
	$css:=$css+".footer { text-align: center; color: #7f8c8d; margin-top: 20px; font-size: 12px; }\r\n"
	
	return $css
