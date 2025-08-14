property class : 4D:C1709.Class
property classInstance : 4D:C1709.Object
property function : 4D:C1709.Function
property functionName : Text
property t : cs:C1710.Testing
property startTime : Integer
property endTime : Integer
property runtimeErrors : Collection
property tags : Collection  // Collection of tag strings

Class constructor($class : 4D:C1709.Class; $classInstance : 4D:C1709.Object; $function : 4D:C1709.Function; $name : Text; $classCode : Text)
	This:C1470.class:=$class
	This:C1470.classInstance:=$classInstance
	This:C1470.function:=$function
	This:C1470.functionName:=$name
	This:C1470.t:=cs:C1710.Testing.new()
	This:C1470.runtimeErrors:=[]
	This:C1470.tags:=This:C1470._parseTags($classCode || "")
	
Function run()
	This:C1470.startTime:=Milliseconds:C459
	
	// Reset the testing context for this test
	This:C1470.t.resetForNewTest()
	
	// Clear any existing test errors
	If (Storage:C1525.testErrors#Null:C1517)
		Use (Storage:C1525)
			Storage:C1525.testErrors.clear()
		End use 
	End if 
	
	// Set up error handler to capture runtime errors
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	This:C1470.function.apply(This:C1470.classInstance; [This:C1470.t])
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
	// Capture any runtime errors that occurred
	If (Storage:C1525.testErrors#Null:C1517) && (Storage:C1525.testErrors.length>0)
		var $error : Object
		For each ($error; Storage:C1525.testErrors)
			This:C1470.runtimeErrors.push(OB Copy:C1225($error))
		End for each 
		
		// Mark test as failed if runtime errors occurred
		This:C1470.t.fail()
	End if 
	
	This:C1470.endTime:=Milliseconds:C459
	
Function getResult() : Object
	var $duration : Integer
	$duration:=This:C1470.endTime-This:C1470.startTime
	
	return New object:C1471(\
		"name"; This:C1470.functionName; \
		"passed"; Not:C34(This:C1470.t.failed); \
		"failed"; This:C1470.t.failed; \
		"duration"; $duration; \
		"suite"; This:C1470.class.name; \
		"runtimeErrors"; This:C1470.runtimeErrors; \
		"logMessages"; This:C1470.t.logMessages; \
		"tags"; This:C1470.tags\
		)

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