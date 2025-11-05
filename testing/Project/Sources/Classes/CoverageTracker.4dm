// Tracks code coverage data during test execution
// Stores line execution counts and provides coverage statistics

property coverageData : Object  // Map of method/class name -> line coverage
property enabledMethods : Collection  // Collection of methods being tracked
property startTime : Integer
property endTime : Integer

Class constructor()
	This.coverageData:=New object
	This.enabledMethods:=[]
	This.startTime:=0
	This.endTime:=0
	
Function initialize()
	// Initialize shared storage for coverage tracking
	Use (Storage)
		If (Storage.coverage=Null)
			Storage.coverage:=New shared object("data"; New shared object)
		Else 
			Storage.coverage.data:=New shared object
		End if 
	End use 
	This.startTime:=Milliseconds
	
Function recordLine($methodName : Text; $lineNumber : Integer)
	// Record that a line was executed
	// This method is called by instrumented code
	
	If (Storage.coverage=Null) || (Storage.coverage.data=Null)
		return 
	End if 
	
	Use (Storage.coverage.data)
		If (Storage.coverage.data[$methodName]=Null)
			Storage.coverage.data[$methodName]:=New shared object
		End if 
		
		Use (Storage.coverage.data[$methodName])
			var $currentCount : Integer
			$currentCount:=Num(Storage.coverage.data[$methodName][String($lineNumber)])
			Storage.coverage.data[$methodName][String($lineNumber)]:=$currentCount+1
		End use 
	End use 
	
Function collectData()
	// Collect coverage data from shared storage
	This.endTime:=Milliseconds
	
	If (Storage.coverage=Null) || (Storage.coverage.data=Null)
		return 
	End if 
	
	Use (Storage.coverage.data)
		This.coverageData:=OB Copy(Storage.coverage.data; ck shared; This.coverageData)
	End use 
	
Function cleanup()
	// Clean up shared storage
	Use (Storage)
		If (Storage.coverage#Null)
			Storage.coverage.data:=New shared object
		End if 
	End use 
	
Function getMethodCoverage($methodName : Text) : Object
	// Get coverage data for a specific method
	var $coverage : Object
	$coverage:=This.coverageData[$methodName]
	
	If ($coverage=Null)
		$coverage:=New object
	End if 
	
	return $coverage
	
Function getCoverageStats() : Object
	// Calculate overall coverage statistics
	var $stats : Object
	var $totalLines; $coveredLines : Integer
	var $methodName : Text
	
	$totalLines:=0
	$coveredLines:=0
	
	For each ($methodName; This.coverageData)
		var $methodCoverage : Object
		$methodCoverage:=This.coverageData[$methodName]
		
		var $lineNum : Text
		For each ($lineNum; $methodCoverage)
			$totalLines:=$totalLines+1
			If (Num($methodCoverage[$lineNum])>0)
				$coveredLines:=$coveredLines+1
			End if 
		End for each 
	End for each 
	
	var $coveragePercent : Real
	If ($totalLines>0)
		$coveragePercent:=($coveredLines/$totalLines)*100
	Else 
		$coveragePercent:=0
	End if 
	
	$stats:=New object(\
		"totalLines"; $totalLines; \
		"coveredLines"; $coveredLines; \
		"uncoveredLines"; $totalLines-$coveredLines; \
		"coveragePercent"; $coveragePercent; \
		"methodCount"; This.coverageData#Null ? Length(This.coverageData) : 0; \
		"duration"; This.endTime-This.startTime\
		)
	
	return $stats
	
Function getDetailedStats() : Collection
	// Get detailed coverage statistics per method
	var $methodStats : Collection
	$methodStats:=[]
	
	var $methodName : Text
	For each ($methodName; This.coverageData)
		var $methodCoverage : Object
		$methodCoverage:=This.coverageData[$methodName]
		
		var $totalLines; $coveredLines : Integer
		$totalLines:=0
		$coveredLines:=0
		
		var $lineNum : Text
		For each ($lineNum; $methodCoverage)
			$totalLines:=$totalLines+1
			If (Num($methodCoverage[$lineNum])>0)
				$coveredLines:=$coveredLines+1
			End if 
		End for each 
		
		var $coveragePercent : Real
		If ($totalLines>0)
			$coveragePercent:=($coveredLines/$totalLines)*100
		Else 
			$coveragePercent:=0
		End if 
		
		$methodStats.push(New object(\
			"method"; $methodName; \
			"totalLines"; $totalLines; \
			"coveredLines"; $coveredLines; \
			"uncoveredLines"; $totalLines-$coveredLines; \
			"coveragePercent"; $coveragePercent\
			))
	End for each 
	
	return $methodStats
	
Function getUncoveredLines($methodName : Text) : Collection
	// Get line numbers that were not covered
	var $uncoveredLines : Collection
	$uncoveredLines:=[]
	
	var $methodCoverage : Object
	$methodCoverage:=This.coverageData[$methodName]
	
	If ($methodCoverage=Null)
		return $uncoveredLines
	End if 
	
	var $lineNum : Text
	For each ($lineNum; $methodCoverage)
		If (Num($methodCoverage[$lineNum])=0)
			$uncoveredLines.push(Num($lineNum))
		End if 
	End for each 
	
	return $uncoveredLines.orderBy()
	
Function mergeData($otherTracker : cs.CoverageTracker)
	// Merge coverage data from another tracker (for parallel execution)
	var $methodName : Text
	For each ($methodName; $otherTracker.coverageData)
		If (This.coverageData[$methodName]=Null)
			This.coverageData[$methodName]:=OB Copy($otherTracker.coverageData[$methodName])
		Else 
			// Merge line counts
			var $lineNum : Text
			For each ($lineNum; $otherTracker.coverageData[$methodName])
				var $existingCount : Integer
				$existingCount:=Num(This.coverageData[$methodName][$lineNum])
				var $otherCount : Integer
				$otherCount:=Num($otherTracker.coverageData[$methodName][$lineNum])
				This.coverageData[$methodName][$lineNum]:=$existingCount+$otherCount
			End for each 
		End if 
	End for each 
