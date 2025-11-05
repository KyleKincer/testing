// Tracks code coverage during test execution
// Stores which lines of code have been executed

property methodCoverage : Object  // Map of methodName -> line coverage data
property enabled : Boolean
property startTime : Integer
property endTime : Integer

Class constructor()
	This.methodCoverage:=New object
	This.enabled:=False
	This.startTime:=0
	This.endTime:=0
	
Function enable()
	// Enable coverage tracking
	This.enabled:=True
	This.startTime:=Milliseconds
	This._initializeSharedStorage()
	
Function disable()
	// Disable coverage tracking
	This.enabled:=False
	This.endTime:=Milliseconds
	
Function _initializeSharedStorage()
	// Initialize shared storage for cross-process coverage data
	Use (Storage)
		If (Storage.coverage=Null)
			Storage.coverage:=New shared object("data"; New shared object)
		Else 
			Use (Storage.coverage)
				Storage.coverage.data:=New shared object
			End use 
		End if 
	End use 
	
Function track($methodName : Text; $lineNumber : Integer)
	// Record that a specific line was executed
	// This is called by instrumented code
	
	If (Not(This.enabled))
		return 
	End if 
	
	// Use shared storage for thread-safe tracking
	If (Storage.coverage#Null)
		Use (Storage.coverage)
			var $methodData : Object
			If (Storage.coverage.data[$methodName]=Null)
				Storage.coverage.data[$methodName]:=New shared object("lines"; New shared collection)
			End if 
			
			Use (Storage.coverage.data[$methodName])
				// Add line number if not already tracked
				If (Storage.coverage.data[$methodName].lines.indexOf($lineNumber)=-1)
					Storage.coverage.data[$methodName].lines.push($lineNumber)
				End if 
			End use 
		End use 
	End if 
	
Function collectResults() : Object
	// Collect coverage data from shared storage
	var $results : Object
	$results:=New object("methodCoverage"; New object; "totalLines"; 0; "coveredLines"; 0; "coveragePercent"; 0)
	
	If (Storage.coverage#Null)
		Use (Storage.coverage)
			var $methodName : Text
			For each ($methodName; Storage.coverage.data)
				var $methodData : Object
				$methodData:=OB Copy(Storage.coverage.data[$methodName]; ck shared; *)
				$results.methodCoverage[$methodName]:=$methodData
			End for each 
		End use 
	End if 
	
	return $results
	
Function getCoverageForMethod($methodName : Text) : Collection
	// Get the covered line numbers for a specific method
	If (Storage.coverage#Null)
		Use (Storage.coverage)
			If (Storage.coverage.data[$methodName]#Null)
				return OB Copy(Storage.coverage.data[$methodName].lines; ck shared)
			End if 
		End use 
	End if 
	
	return New collection
	
Function clear()
	// Clear all coverage data
	This._initializeSharedStorage()
	This.methodCoverage:=New object
	
Function getStats() : Object
	// Calculate coverage statistics
	var $results : Object
	$results:=This.collectResults()
	
	var $totalMethods : Integer
	var $methodsWithCoverage : Integer
	var $methodName : Text
	
	$totalMethods:=0
	$methodsWithCoverage:=0
	
	For each ($methodName; $results.methodCoverage)
		$totalMethods+=1
		var $methodData : Object
		$methodData:=$results.methodCoverage[$methodName]
		If ($methodData.lines.length>0)
			$methodsWithCoverage+=1
		End if 
	End for each 
	
	var $stats : Object
	$stats:=New object(\
		"totalMethods"; $totalMethods; \
		"coveredMethods"; $methodsWithCoverage; \
		"methodCoveragePercent"; ($totalMethods>0) ? Round(($methodsWithCoverage/$totalMethods)*100; 2) : 0; \
		"duration"; This.endTime-This.startTime\
		)
	
	return $stats
