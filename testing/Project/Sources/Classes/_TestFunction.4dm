property class : 4D:C1709.Class
property classInstance : 4D:C1709.Object
property function : 4D:C1709.Function
property functionName : Text
property t : cs:C1710.Testing
property startTime : Integer
property endTime : Integer
property runtimeErrors : Collection
property skipped : Boolean
property tags : Collection  // Collection of tag strings
property useTransactions : Boolean  // Whether to auto-manage transactions for this test
property triggerControl : Text  // "default", "enabled", "disabled"
property runner : Object  // Reference to the TestRunner

Class constructor($class : 4D:C1709.Class; $classInstance : 4D:C1709.Object; $function : 4D:C1709.Function; $name : Text; $classCode : Text; $runner : Object)
	This:C1470.class:=$class
	This:C1470.classInstance:=$classInstance
	This:C1470.function:=$function
        This:C1470.functionName:=$name
        This:C1470.t:=cs:C1710.Testing.new()
        This:C1470.t.classInstance:=$classInstance
        This:C1470.runtimeErrors:=[]
        This:C1470.skipped:=False:C215
        This:C1470.tags:=This:C1470._parseTags($classCode || "")
        This:C1470.useTransactions:=This:C1470._shouldUseTransactions($classCode || "")
        This:C1470.triggerControl:=This:C1470._parseTriggerControl($classCode || "")
        This:C1470.runner:=$runner
	
Function run()
        This:C1470.startTime:=Milliseconds:C459

        // Reset the testing context for this test
        This:C1470.t.resetForNewTest()

        var $processNumber : Integer
        $processNumber:=Current process:C322

        // Ensure shared error storage exists
        If (Storage:C1525.testErrors=Null:C1517)
                Use (Storage:C1525)
                        Storage:C1525.testErrors:=New shared collection:C1527
                End use
        End if

        // Clear any existing errors recorded for this process
        This:C1470._clearProcessErrors($processNumber)

        // Skip test early if tagged to skip
        If (This:C1470.shouldSkip())
                This:C1470.skipped:=True:C214
                This:C1470.endTime:=Milliseconds:C459
                return
        End if

	// Apply test-level trigger control if specified
	This:C1470._applyTriggerControl()

	// Start transaction if configured to use transactions
	var $transactionStarted : Boolean
	$transactionStarted:=False
	If (This:C1470.useTransactions)
		START TRANSACTION:C239
		$transactionStarted:=True
	End if 
	
        This:C1470.function.apply(This:C1470.classInstance; [This:C1470.t])
	
        // Capture any runtime errors that occurred in this process
        var $processErrors : Collection
        $processErrors:=This:C1470._collectProcessErrors($processNumber)

        If ($processErrors.length>0)
                var $error : Object
                For each ($error; $processErrors)
                        This:C1470.runtimeErrors.push($error)
                End for each

                // Mark test as failed if runtime errors occurred
                This:C1470.t.fail()
        End if
	
	// Handle transaction cleanup
	If ($transactionStarted)
		If (This:C1470.t.failed)
			// Cancel transaction if test failed
			CANCEL TRANSACTION:C241
		Else
			// Always cancel transaction to ensure test isolation
			// Tests should not persist data changes by default
			CANCEL TRANSACTION:C241
		End if
	End if

	// Restore default trigger behavior after test
	This:C1470._restoreTriggerControl()

        This:C1470.endTime:=Milliseconds:C459

Function getResult() : Object
        var $duration : Integer
        $duration:=This:C1470.endTime-This:C1470.startTime

        return New object:C1471(\
                "name"; This:C1470.functionName; \
                "passed"; Not:C34(This:C1470.t.failed) && Not:C34(This:C1470.skipped); \
                "failed"; This:C1470.t.failed; \
                "skipped"; This:C1470.skipped; \
                "duration"; $duration; \
                "suite"; This:C1470.class.name; \
                "runtimeErrors"; This:C1470.runtimeErrors; \
                "logMessages"; This:C1470.t.logMessages; \
                "assertions"; This:C1470.t.assertions; \
                "assertionCount"; This:C1470.t.assertions.length; \
                "tags"; This:C1470.tags; \
                "callChain"; This:C1470.t.failureCallChain\
                )

Function shouldSkip() : Boolean
        return (This:C1470.tags.indexOf("skip")>=0)

Function _parseTags($classCode : Text) : Collection
	// Parse tags from function comments in source code
	// Tags are defined in comments like: // #tags: unit, integration, slow
	var $tags : Collection
	$tags:=[]
	
	If ($classCode#"")
		// Parse tags from source code comments
		$tags:=This:C1470._parseTagsFromSourceCode($classCode)
	End if 
	
	// Default tag if no specific tags found
	If ($tags.length=0)
		$tags.push("unit")  // Default to unit test
	End if 
	
	return $tags

Function _parseTagsFromSourceCode($classCode : Text) : Collection
	// Parse tags from actual source code comments
	var $tags : Collection
	$tags:=[]
	
	// Split into lines and search line by line
	var $lines : Collection
	$lines:=Split string:C1554($classCode; Char:C90(Carriage return:K15:38))
	
	// Find our function and look backwards for tag comments
	var $functionPattern : Text
	$functionPattern:="Function "+This:C1470.functionName
	
	var $lineIndex : Integer
	var $functionLineIndex : Integer
	$functionLineIndex:=-1
	
	// Find the line with our function
	For ($lineIndex; 0; $lines.length-1)
		var $line : Text
		$line:=$lines[$lineIndex]
		If (Position:C15($functionPattern; $line)>0)
			$functionLineIndex:=$lineIndex
			break
		End if 
	End for 
	
	// If we found our function, look backwards for tag comments
	If ($functionLineIndex>=0)
		For ($lineIndex; $functionLineIndex-1; 0; -1)
			$line:=$lines[$lineIndex]
			
			// Stop if we hit another function or non-comment line
			If (Position:C15("Function "; $line)>0)
				break  // Hit another function
			End if 
			
			// Look for #tags: in this line
			var $tagPos : Integer
			$tagPos:=Position:C15("#tags:"; $line)
			If ($tagPos>0)
				// Extract tags from this line
				var $tagsPart : Text
				$tagsPart:=Substring:C12($line; $tagPos+6)  // Skip "#tags:"
				$tagsPart:=Replace string:C233($tagsPart; " "; "")  // Remove spaces
				
				// Split tags by comma
				If ($tagsPart#"")
					var $tagList : Collection
					$tagList:=Split string:C1554($tagsPart; ",")
					var $tag : Text
					For each ($tag; $tagList)
						$tag:=Replace string:C233($tag; " "; "")  // Remove any remaining spaces
						If ($tag#"")
							$tags.push($tag)
						End if 
					End for each 
				End if 
				break  // Found tags, stop looking
			End if 
			
			// Stop if we hit a non-comment line (not starting with // or empty)
			var $trimmedLine : Text
			$trimmedLine:=Replace string:C233($line; " "; "")
			$trimmedLine:=Replace string:C233($trimmedLine; Char:C90(Tab:K15:37); "")
			If ($trimmedLine#"") && (Position:C15("//"; $trimmedLine)#1)
				break  // Hit non-comment line
			End if 
		End for 
	End if 
	
	return $tags


Function hasTags($tagList : Collection) : Boolean
	// Check if this test has any of the specified tags
	var $tag : Text
	For each ($tag; $tagList)
		If (This:C1470.tags.indexOf($tag)>=0)
			return True:C214
		End if 
	End for each 
	return False:C215

Function hasAllTags($tagList : Collection) : Boolean
	// Check if this test has all of the specified tags
	var $tag : Text
	For each ($tag; $tagList)
		If (This:C1470.tags.indexOf($tag)<0)
			return False:C215
		End if 
	End for each 
	return True:C214

Function _shouldUseTransactions($classCode : Text) : Boolean
	// Determine if this test should use automatic transaction management
	// Default is true unless explicitly disabled via comment

	If ($classCode="")
		return True  // Default to using transactions
	End if

	// Look for transaction control comments in the function
	var $lines : Collection
	$lines:=Split string:C1554($classCode; Char:C90(Carriage return:K15:38))

	// Find our function and look for transaction control comments
	var $functionPattern : Text
	$functionPattern:="Function "+This:C1470.functionName

	var $lineIndex : Integer
	var $functionLineIndex : Integer
	$functionLineIndex:=-1

	// Find the line with our function
	For ($lineIndex; 0; $lines.length-1)
		var $line : Text
		$line:=$lines[$lineIndex]
		If (Position:C15($functionPattern; $line)>0)
			$functionLineIndex:=$lineIndex
			break
		End if
	End for

	// If we found our function, look backwards for transaction control comments
	If ($functionLineIndex>=0)
		For ($lineIndex; $functionLineIndex-1; 0; -1)
			$line:=$lines[$lineIndex]

			// Stop if we hit another function
			If (Position:C15("Function "; $line)>0)
				break
			End if

			// Look for #transaction: comments (following existing #tags: pattern)
			If (Position:C15("#transaction:"; $line)>0)
				var $transactionValue : Text
				$transactionValue:=Substring:C12($line; Position:C15("#transaction:"; $line)+13)
				$transactionValue:=Replace string:C233($transactionValue; " "; "")  // Remove spaces

				// Check for explicit disable
				If ($transactionValue="false")
					return False
				End if
				break
			End if

			// Stop if we hit a non-comment line
			var $trimmedLine : Text
			$trimmedLine:=Replace string:C233($line; " "; "")
			$trimmedLine:=Replace string:C233($trimmedLine; Char:C90(Tab:K15:37); "")
			If ($trimmedLine#"") && (Position:C15("//"; $trimmedLine)#1)
				break
			End if
		End for
	End if

        // Default to using transactions for test isolation
        return True

Function _parseTriggerControl($classCode : Text) : Text
	// Parse trigger control from test function comments
	// Returns "default", "enabled", or "disabled"
	// #triggers: enabled  - Force triggers ON for this test
	// #triggers: disabled - Force triggers OFF for this test

	If ($classCode="")
		return "default"
	End if

	var $lines : Collection
	$lines:=Split string:C1554($classCode; Char:C90(Carriage return:K15:38))

	var $functionPattern : Text
	$functionPattern:="Function "+This:C1470.functionName

	var $lineIndex : Integer
	var $functionLineIndex : Integer
	$functionLineIndex:=-1

	// Find the line with our function
	For ($lineIndex; 0; $lines.length-1)
		var $line : Text
		$line:=$lines[$lineIndex]
		If (Position:C15($functionPattern; $line)>0)
			$functionLineIndex:=$lineIndex
			break
		End if
	End for

	// If we found our function, look backwards for trigger control comments
	If ($functionLineIndex>=0)
		For ($lineIndex; $functionLineIndex-1; 0; -1)
			$line:=$lines[$lineIndex]

			// Stop if we hit another function
			If (Position:C15("Function "; $line)>0)
				break
			End if

			// Look for #triggers: comments
			If (Position:C15("#triggers:"; $line)>0)
				var $triggerValue : Text
				$triggerValue:=Substring:C12($line; Position:C15("#triggers:"; $line)+10)
				$triggerValue:=Replace string:C233($triggerValue; " "; "")  // Remove spaces

				If ($triggerValue="enabled")
					return "enabled"
				Else
					If ($triggerValue="disabled")
						return "disabled"
					End if
				End if
				break
			End if

			// Stop if we hit a non-comment line
			var $trimmedLine : Text
			$trimmedLine:=Replace string:C233($line; " "; "")
			$trimmedLine:=Replace string:C233($trimmedLine; Char:C90(Tab:K15:37); "")
			If ($trimmedLine#"") && (Position:C15("//"; $trimmedLine)#1)
				break
			End if
		End for
	End if

	return "default"

Function _applyTriggerControl()
	// Apply test-level trigger control based on comment annotation
	If (This:C1470.runner=Null:C1517)
		return  // No runner reference, cannot control triggers
	End if

	Case of
		: (This:C1470.triggerControl="enabled")
			This:C1470.runner.enableTriggersForTest()
		: (This:C1470.triggerControl="disabled")
			This:C1470.runner.disableTriggersForTest()
			// "default" case: do nothing, use default behavior
	End case

Function _restoreTriggerControl()
	// Restore default trigger behavior after test completes
	If (This:C1470.runner#Null:C1517)
		This:C1470.runner.restoreDefaultTriggerBehavior()
	End if

Function _clearProcessErrors($processNumber : Integer)
        If (Storage:C1525.testErrors#Null:C1517)
                Use (Storage:C1525.testErrors)
                        var $index : Integer
                        For ($index; Storage:C1525.testErrors.length-1; 0; -1)
                                var $error : Object
                                $error:=Storage:C1525.testErrors[$index]

                                If (This:C1470._errorBelongsToProcess($error; $processNumber))
                                        Storage:C1525.testErrors.remove($index)
                                End if
                        End for
                End use
        End if

Function _collectProcessErrors($processNumber : Integer) : Collection
        var $processErrors : Collection
        $processErrors:=New collection:C1472

        If (Storage:C1525.testErrors#Null:C1517)
                Use (Storage:C1525.testErrors)
                        var $index : Integer
                        For ($index; Storage:C1525.testErrors.length-1; 0; -1)
                                var $error : Object
                                $error:=Storage:C1525.testErrors[$index]

                                If (This:C1470._errorBelongsToProcess($error; $processNumber))
                                        $processErrors.push(OB Copy:C1225($error))
                                        Storage:C1525.testErrors.remove($index)
                                End if
                        End for
                End use
        End if

        return $processErrors

Function _errorBelongsToProcess($error : Object; $processNumber : Integer) : Boolean
        If ($error=Null:C1517)
                return False:C215
        End if

        var $context : Text
        $context:=$error.context || ""

        If ($context="global")
                return False:C215
        End if

        If ($error.processNumber#Null:C1517)
                return ($error.processNumber=$processNumber)
        End if

        // Legacy support: assume errors without process information belong to the current process
        return True:C214
