property hostStorage : 4D:C1709.Object
property userParams : 4D:C1709.Object
property enabled : Boolean
property instrumentedMethods : Collection
property methodSnapshots : Collection
property backupFolder : 4D:C1709.Folder
property coverageOutputFolder : 4D:C1709.Folder
property coverageOutputPath : Text
property coverageRecordMethodName : Text
property coverageHelperExisted : Boolean
property coverageHelperOriginalCode : Text
property createdBackupFiles : Collection
property hitsSnapshot : Object
property errorDuringRun : Boolean
property classStore : 4D:C1709.Object

Class constructor($cs : 4D:C1709.Object; $hostStorage : 4D:C1709.Object; $userParams : 4D:C1709.Object)
	This:C1470.classStore:=$cs
	This:C1470.hostStorage:=$hostStorage
	This:C1470.userParams:=$userParams || New object:C1471
	This:C1470.enabled:=False:C215
	This:C1470.instrumentedMethods:=New collection:C1472
	This:C1470.methodSnapshots:=New collection:C1472
	This:C1470.coverageRecordMethodName:="__TEST_COVERAGE_HIT"
	This:C1470.coverageHelperExisted:=False:C215
	This:C1470.coverageHelperOriginalCode:=""
	This:C1470.createdBackupFiles:=New collection:C1472
	This:C1470.coverageOutputPath:="test-results/coverage/coverage.json"
	This:C1470.errorDuringRun:=False:C215
	This:C1470.hitsSnapshot:=New object:C1471

Function enable()->$enabled : Boolean
	var $shouldEnable : Boolean
	$shouldEnable:=This:C1470._shouldEnableCoverage()
	This:C1470._prepareOutputFolders()
	This:C1470._ensureCleanState()

	If (Not:C34($shouldEnable))
		return False:C215
	End if

	This:C1470.enabled:=True:C214
	This:C1470._prepareStorage()
	This:C1470._ensureCoverageRecordMethod()
	This:C1470._instrumentHostProject()
	LOG EVENT:C667(Into system standard outputs:K38:9; "Coverage instrumentation enabled for "+String:C10(This:C1470.instrumentedMethods.length)+" code regions\r\n"; Information message:K38:1)

	return True:C214

Function finalize($testResults : Object) : Object
	If (Not:C34(This:C1470.enabled))
		return Null:C1517
	End if

	var $hits : Object
	$hits:=This:C1470._collectHitsFromStorage()
	var $coverageSummary : Object
	$coverageSummary:=This:C1470._buildCoverageSummary($hits)
	This:C1470._restoreInstrumentedCode()
	This:C1470._cleanupStorage()
	This:C1470._writeCoverageReport($coverageSummary)

	If ($testResults#Null:C1517)
		$testResults.coverage:=$coverageSummary
	End if

	return $coverageSummary

Function handleRunError($errorInfo : Object)
	This:C1470.errorDuringRun:=True:C214
	This:C1470._restoreInstrumentedCode()
	This:C1470._cleanupStorage()
	If ($errorInfo#Null:C1517)
		LOG EVENT:C667(Into system standard outputs:K38:9; "Coverage instrumentation aborted due to runtime error"+Char:C90(Carriage return:K15:38); Error message:K38:3)
	End if

Function _shouldEnableCoverage() : Boolean
	var $coverageParam : Text
	$coverageParam:=(This:C1470.userParams#Null:C1517) ? (This:C1470.userParams.coverage || "") : ""

	If ($coverageParam="")
		return False:C215
	End if

	Case of
		: ($coverageParam="enabled")
			return True:C214
		: ($coverageParam="true")
			return True:C214
		: ($coverageParam="on")
			return True:C214
		: ($coverageParam="1")
			return True:C214
	Else 
		return False:C215
	End case

Function _prepareOutputFolders()
	var $projectRoot : 4D:C1709.Folder
	$projectRoot:=Folder:C1567(fk database folder:K87:14; *)

	var $testResultsFolder : 4D:C1709.Folder
	$testResultsFolder:=$projectRoot.folder("test-results")
	If (Not:C34($testResultsFolder.exists))
		$testResultsFolder.create()
	End if

	This:C1470.coverageOutputFolder:=$testResultsFolder.folder("coverage")
	If (Not:C34(This:C1470.coverageOutputFolder.exists))
		This:C1470.coverageOutputFolder.create()
	End if

	This:C1470.backupFolder:=This:C1470.coverageOutputFolder.folder("backups")
	If (Not:C34(This:C1470.backupFolder.exists))
		This:C1470.backupFolder.create()
	End if

Function _ensureCleanState()
	If (This:C1470.backupFolder=Null:C1517)
		return
	End if

	var $backupFiles : Collection
	$backupFiles:=This:C1470.backupFolder.files("*.json")

	If ($backupFiles=Null:C1517)
		return
	End if

	If ($backupFiles.length>0)
		LOG EVENT:C667(Into system standard outputs:K38:9; "Previous coverage instrumentation detected - restoring originals"+Char:C90(Carriage return:K15:38); Warning message:K38:2)
	End if

	var $file : 4D:C1709.File
	For each ($file; $backupFiles)
		var $jsonText : Text
		$jsonText:=$file.getText("UTF-8")
		If ($jsonText#"")
			var $snapshot : Object
			$snapshot:=JSON Parse:C1216($jsonText)
			If ($snapshot#Null:C1517)
				This:C1470._restoreSnapshot($snapshot)
			End if
		End if
		$file.delete()
	End for each

Function _restoreSnapshot($snapshot : Object)
	If ($snapshot=Null:C1517)
		return
	End if

	var $path : Text
	$path:=$snapshot.methodPath || ""

	var $code : Text
	$code:=$snapshot.originalCode || ""

	If ($path#"")
		METHOD SET CODE($path; $code; *)
	End if

Function _prepareStorage()
	Use (Storage:C1525)
		If (Storage:C1525.testCoverage=Null:C1517)
			Storage:C1525.testCoverage:=New shared object:C1526("hits"; New shared object:C1526)
		Else 
			Use (Storage:C1525.testCoverage)
				Storage:C1525.testCoverage.hits:=New shared object:C1526
			End use
		End if
	End use

Function _ensureCoverageRecordMethod()
	var $methodPath : Text
	$methodPath:=This:C1470.coverageRecordMethodName

	var $existingFile : 4D:C1709.File
	$existingFile:=Folder:C1567(fk database folder:K87:14; *).folder("Project/Sources/Methods").file($methodPath+".4dm")

	If ($existingFile.exists)
		This:C1470.coverageHelperExisted:=True:C214
		var $original : Text
		METHOD GET CODE:C1190($methodPath; $original; *)
		This:C1470.coverageHelperOriginalCode:=$original
	Else 
		This:C1470.coverageHelperExisted:=False:C215
		This:C1470.coverageHelperOriginalCode:=""
	End if

	var $methodCode : Text
	$methodCode:=This:C1470._coverageRecordMethodSource()
	METHOD SET CODE($methodPath; $methodCode; *)

Function _coverageRecordMethodSource() : Text
	var $lines : Collection
	$lines:=New collection:C1472
	$lines.push("// Auto-generated coverage hook")
	$lines.push("#DECLARE($methodId : Text; $lineNumber : Integer)")
	$lines.push("If (($methodId=\"\") || ($lineNumber<=0))")
	$lines.push("    return")
	$lines.push("End if")
	$lines.push("Use (Storage:C1525)")
	$lines.push("    If (Storage:C1525.testCoverage=Null:C1517)")
	$lines.push("        Storage:C1525.testCoverage:=New shared object:C1526(\"hits\"; New shared object:C1526)")
	$lines.push("    End if")
	$lines.push("    Use (Storage:C1525.testCoverage)")
	$lines.push("        If (Storage:C1525.testCoverage.hits=Null:C1517)")
	$lines.push("            Storage:C1525.testCoverage.hits:=New shared object:C1526")
	$lines.push("        End if")
	$lines.push("        Use (Storage:C1525.testCoverage.hits)")
	$lines.push("            var $methodHits : Object")
	$lines.push("            $methodHits:=Storage:C1525.testCoverage.hits[$methodId]")
	$lines.push("            If ($methodHits=Null:C1517)")
	$lines.push("                Storage:C1525.testCoverage.hits[$methodId]:=New shared object:C1526")
	$lines.push("                $methodHits:=Storage:C1525.testCoverage.hits[$methodId]")
	$lines.push("            End if")
	$lines.push("            Use ($methodHits)")
	$lines.push("                $methodHits[String:C10($lineNumber)]:=True:C214")
	$lines.push("            End use")
	$lines.push("        End use")
	$lines.push("    End use")
	$lines.push("End use")

	return $lines.join(Char:C90(Carriage return:K15:38))

Function _instrumentHostProject()
	This:C1470._instrumentProjectMethods()
	This:C1470._instrumentClassFiles()

Function _instrumentProjectMethods()
	var $methodsFolder : 4D:C1709.Folder
	$methodsFolder:=Folder:C1567(fk database folder:K87:14; *).folder("Project/Sources/Methods")
	If (Not:C34($methodsFolder.exists))
		return
	End if

	var $files : Collection
	$files:=$methodsFolder.files("*.4dm")
	If ($files=Null:C1517)
		return
	End if

	var $file : 4D:C1709.File
	For each ($file; $files)
		This:C1470._instrumentProjectMethodFile($file)
	End for each

Function _instrumentProjectMethodFile($file : 4D:C1709.File)
	If (Not:C34($file.exists))
		return
	End if

	var $fileName : Text
	$fileName:=$file.name
	var $methodName : Text
	var $extPos : Integer
	$extPos:=Position:C15(".4dm"; $fileName)
	If ($extPos>0)
		$methodName:=Substring:C12($fileName; 1; $extPos-1)
	Else 
		$methodName:=$fileName
	End if

	If ($methodName=This:C1470.coverageRecordMethodName)
		return
	End if

	var $methodPath : Text
	$methodPath:=$methodName

	var $originalCode : Text
	METHOD GET CODE:C1190($methodPath; $originalCode; *)

	If (This:C1470._hasCoverageSkipAnnotation($originalCode))
		return
	End if

	var $instrumentation : Object
	$instrumentation:=This:C1470._instrumentCode($originalCode; $methodPath; "method"; "")

	If ($instrumentation=Null:C1517)
		return
	End if

	If ($instrumentation.lines.length=0)
		return
	End if

	This:C1470._writeBackup($methodPath; $originalCode)
	METHOD SET CODE($methodPath; $instrumentation.code; *)
	This:C1470._registerInstrumentedEntries($instrumentation.entries)
	This:C1470.methodSnapshots.push(New object:C1471("methodPath"; $methodPath; "originalCode"; $originalCode))

Function _instrumentClassFiles()
	var $classFolder : 4D:C1709.Folder
	$classFolder:=Folder:C1567(fk database folder:K87:14; *).folder("Project/Sources/Classes")
	If (Not:C34($classFolder.exists))
		return
	End if

	var $classFiles : Collection
	$classFiles:=$classFolder.files("*.4dm")
	If ($classFiles=Null:C1517)
		return
	End if

	var $file : 4D:C1709.File
	For each ($file; $classFiles)
		This:C1470._instrumentClassFile($file)
	End for each

Function _instrumentClassFile($file : 4D:C1709.File)
	var $fileName : Text
	$fileName:=$file.name
	var $className : Text
	var $extPos : Integer
	$extPos:=Position:C15(".4dm"; $fileName)
	If ($extPos>0)
		$className:=Substring:C12($fileName; 1; $extPos-1)
	Else 
		$className:=$fileName
	End if
	If ($className="")
		return
	End if

	var $classPath : Text
	$classPath:="[class]/"+$className
	var $originalCode : Text
	METHOD GET CODE:C1190($classPath; $originalCode; *)

	If (This:C1470._hasCoverageSkipAnnotation($originalCode))
		return
	End if

	var $instrumentation : Object
	$instrumentation:=This:C1470._instrumentClassCode($className; $originalCode)

	If ($instrumentation=Null:C1517)
		return
	End if

	If ($instrumentation.linesTotal=0)
		return
	End if

	This:C1470._writeBackup($classPath; $originalCode)
	METHOD SET CODE($classPath; $instrumentation.code; *)
	This:C1470._registerInstrumentedEntries($instrumentation.entries)
	This:C1470.methodSnapshots.push(New object:C1471("methodPath"; $classPath; "originalCode"; $originalCode))

Function _writeBackup($methodPath : Text; $originalCode : Text)
	If (This:C1470.backupFolder=Null:C1517)
		return
	End if

	var $snapshot : Object
	$snapshot:=New object:C1471("methodPath"; $methodPath; "originalCode"; $originalCode)
	var $jsonText : Text
	$jsonText:=JSON Stringify:C1217($snapshot; *)
	var $fileName : Text
	$fileName:=Replace string:C233($methodPath; "/"; "_")
	$fileName:=Replace string:C233($fileName; ":"; "_")
	$fileName:=Replace string:C233($fileName; "["; "_")
	$fileName:=Replace string:C233($fileName; "]"; "_")
	$fileName:=$fileName+".json"
	var $backupFile : 4D:C1709.File
	$backupFile:=This:C1470.backupFolder.file($fileName)
	$backupFile.setText($jsonText; "UTF-8")
	This:C1470.createdBackupFiles.push($backupFile)

Function _registerInstrumentedEntries($entries : Collection)
	If ($entries=Null:C1517)
		return
	End if

	var $entry : Object
	For each ($entry; $entries)
		This:C1470.instrumentedMethods.push($entry)
	End for each

Function _instrumentCode($code : Text; $methodId : Text; $context : Text; $className : Text) : Object
	var $lines : Collection
	$lines:=Split string:C1554($code; Char:C90(Carriage return:K15:38))
	If ($lines=Null:C1517)
		return Null:C1517
	End if

	var $instrumentedLines : Collection
	$instrumentedLines:=New collection:C1472
	var $entries : Collection
	$entries:=New collection:C1472
	var $lineNumbers : Collection
	$lineNumbers:=New collection:C1472

	var $lineIndex : Integer
	var $lineText : Text
	var $trimmed : Text
	var $inBlockComment : Boolean
	$inBlockComment:=False:C215

	For ($lineIndex; 0; $lines.length-1)
		$lineText:=$lines[$lineIndex]
		$trimmed:=This:C1470._trimLine($lineText)

		If ($inBlockComment)
			$instrumentedLines.push($lineText)
			If (This:C1470._endsBlockComment($trimmed))
				$inBlockComment:=False:C215
			End if
			continue
		End if

		If (This:C1470._startsBlockComment($trimmed))
			$inBlockComment:=Not:C34(This:C1470._endsBlockComment($trimmed))
			$instrumentedLines.push($lineText)
			continue
		End if

		If (This:C1470._shouldInstrumentLine($trimmed; $context))
			var $instrumentLine : Text
			$instrumentLine:=This:C1470._buildInstrumentationLine($lineText; $methodId; $lineIndex+1)
			$instrumentedLines.push($instrumentLine)
			$lineNumbers.push($lineIndex+1)
		End if

		$instrumentedLines.push($lineText)
	End for

	If ($lineNumbers.length=0)
		return Null:C1517
	End if

	$entries.push(New object:C1471(\
		"methodId"; $methodId; \
		"lines"; $lineNumbers; \
		"context"; $context; \
		"className"; $className; \
		"displayName"; This:C1470._buildDisplayName($methodId; $context; $className)
		))

	return New object:C1471(\
		"code"; $instrumentedLines.join(Char:C90(Carriage return:K15:38)); \
		"lines"; $lineNumbers; \
		"entries"; $entries\
		)

Function _instrumentClassCode($className : Text; $code : Text) : Object
	var $lines : Collection
	$lines:=Split string:C1554($code; Char:C90(Carriage return:K15:38))
	If ($lines=Null:C1517)
		return Null:C1517
	End if

	var $instrumentedLines : Collection
	$instrumentedLines:=New collection:C1472
	var $entries : Collection
	$entries:=New collection:C1472
	var $currentFunctionId : Text
	$currentFunctionId:=""
	var $currentFunctionName : Text
	$currentFunctionName:=""
	var $currentLineNumbers : Collection
	$currentLineNumbers:=New collection:C1472
	var $inBlockComment : Boolean
	$inBlockComment:=False:C215

	var $lineIndex : Integer
	For ($lineIndex; 0; $lines.length-1)
		var $lineText : Text
		$lineText:=$lines[$lineIndex]
		var $trimmed : Text
		$trimmed:=This:C1470._trimLine($lineText)

		If ($inBlockComment)
			$instrumentedLines.push($lineText)
			If (This:C1470._endsBlockComment($trimmed))
				$inBlockComment:=False:C215
			End if
			continue
		End if

		If (This:C1470._startsBlockComment($trimmed))
			$inBlockComment:=Not:C34(This:C1470._endsBlockComment($trimmed))
			$instrumentedLines.push($lineText)
			continue
		End if

		If (This:C1470._isClassHeaderLine($trimmed))
			$currentFunctionId:=""
			$currentFunctionName:=""
			$currentLineNumbers:=New collection:C1472
			$instrumentedLines.push($lineText)
			continue
		End if

		If (This:C1470._isConstructorLine($trimmed))
			This:C1470._flushClassFunctionEntry($entries; $currentFunctionId; $className; $currentFunctionName; $currentLineNumbers)
			$currentFunctionName:="constructor"
			$currentFunctionId:=This:C1470._buildClassFunctionId($className; $currentFunctionName)
			$currentLineNumbers:=New collection:C1472
			$instrumentedLines.push($lineText)
			continue
		End if

		If (This:C1470._isFunctionDeclaration($trimmed))
			This:C1470._flushClassFunctionEntry($entries; $currentFunctionId; $className; $currentFunctionName; $currentLineNumbers)
			$currentFunctionName:=This:C1470._extractFunctionName($trimmed)
			$currentFunctionId:=This:C1470._buildClassFunctionId($className; $currentFunctionName)
			$currentLineNumbers:=New collection:C1472
			$instrumentedLines.push($lineText)
			continue
		End if

		If ($currentFunctionId#"")
			If (This:C1470._shouldInstrumentLine($trimmed; "class"))
				var $instrumentLine : Text
				$instrumentLine:=This:C1470._buildInstrumentationLine($lineText; $currentFunctionId; $lineIndex+1)
				$instrumentedLines.push($instrumentLine)
				$currentLineNumbers.push($lineIndex+1)
			End if
		End if

		$instrumentedLines.push($lineText)
	End for

	This:C1470._flushClassFunctionEntry($entries; $currentFunctionId; $className; $currentFunctionName; $currentLineNumbers)

	var $totalLines : Integer
	$totalLines:=0
	var $entry : Object
	For each ($entry; $entries)
		$totalLines:=$totalLines+$entry.lines.length
	End for each

	If ($totalLines=0)
		return Null:C1517
	End if

	return New object:C1471(\
		"code"; $instrumentedLines.join(Char:C90(Carriage return:K15:38)); \
		"entries"; $entries; \
		"linesTotal"; $totalLines\
		)

Function _flushClassFunctionEntry($entries : Collection; $functionId : Text; $className : Text; $functionName : Text; $lineNumbers : Collection)
	If ($functionId#"") && ($lineNumbers.length>0)
		$entries.push(New object:C1471(\
			"methodId"; $functionId; \
			"lines"; $lineNumbers; \
			"context"; "class"; \
			"className"; $className; \
			"displayName"; This:C1470._buildDisplayName($functionId; "class"; $className); \
			"functionName"; $functionName\
			))
	End if

Function _buildDisplayName($methodId : Text; $context : Text; $className : Text) : Text
	If ($context="class")
		return $methodId
	Else 
		return $methodId
	End if

Function _startsBlockComment($trimmed : Text) : Boolean
	return This:C1470._startsWith($trimmed; "/*")

Function _endsBlockComment($trimmed : Text) : Boolean
	return (Position:C15("*/"; $trimmed)>0)

Function _shouldInstrumentLine($trimmed : Text; $context : Text) : Boolean
	If ($trimmed="")
		return False:C215
	End if

	If (This:C1470._startsWith($trimmed; "//"))
		return False:C215
	End if

	If (This:C1470._startsWith($trimmed; "#"))
		return False:C215
	End if

	If (This:C1470._startsWith($trimmed; This:C1470.coverageRecordMethodName))
		return False:C215
	End if

	If (This:C1470._startsWith($trimmed; "property"))
		return False:C215
	End if

	If (This:C1470._startsWith($trimmed; "Function "))
		return False:C215
	End if

	If ($trimmed="End if") || ($trimmed="End for") || ($trimmed="End while") || ($trimmed="End case") || ($trimmed="End for each") || ($trimmed="End use")
		return False:C215
	End if

	If ($trimmed="Else") || (This:C1470._startsWith($trimmed; "Else ")) || ($trimmed="Case of")
		return False:C215
	End if

	If (This:C1470._startsWith($trimmed; ":"))
		return False:C215
	End if

	return True:C214

Function _buildInstrumentationLine($originalLine : Text; $methodId : Text; $lineNumber : Integer) : Text
	var $indent : Text
	$indent:=This:C1470._getIndentation($originalLine)
	return $indent+This:C1470.coverageRecordMethodName+"(\""+$methodId+"\"; "+String:C10($lineNumber)+")"

Function _getIndentation($line : Text) : Text
	var $indent : Text
	$indent:=""
	var $length : Integer
	$length:=Length:C16($line)
	var $index : Integer
	For ($index; 1; $length)
		var $char : Text
		$char:=Substring:C12($line; $index; 1)
		If (($char=" ") || ($char=Char:C90(Tab:K15:9)))
			$indent:=$indent+$char
		Else 
			break
		End if
	End for

	return $indent

Function _trimLine($line : Text) : Text
	var $length : Integer
	$length:=Length:C16($line)
	If ($length=0)
		return ""
	End if

	var $start : Integer
	$start:=1
	While ($start<=$length)
		var $char : Text
		$char:=Substring:C12($line; $start; 1)
		If (($char=" ") || ($char=Char:C90(Tab:K15:9)) || ($char=Char:C90(Carriage return:K15:38)))
			$start:=$start+1
		Else 
			break
		End if
	End while

	If ($start>$length)
		return ""
	End if

	var $end : Integer
	$end:=$length
	While ($end>=$start)
		var $char : Text
		$char:=Substring:C12($line; $end; 1)
		If (($char=" ") || ($char=Char:C90(Tab:K15:9)) || ($char=Char:C90(Carriage return:K15:38)))
			$end:=$end-1
		Else 
			break
		End if
	End while

	return Substring:C12($line; $start; $end-$start+1)

Function _startsWith($text : Text; $prefix : Text) : Boolean
	If ($prefix="")
		return True:C214
	End if

	If (Length:C16($text)<Length:C16($prefix))
		return False:C215
	End if

	return (Substring:C12($text; 1; Length:C16($prefix))=$prefix)

Function _isFunctionDeclaration($trimmed : Text) : Boolean
	return This:C1470._startsWith($trimmed; "Function ")

Function _extractFunctionName($trimmed : Text) : Text
	var $line : Text
	$line:=Substring:C12($trimmed; 10)
	var $openParen : Integer
	$openParen:=Position:C15("("; $line)
	If ($openParen>0)
		return Substring:C12($line; 1; $openParen-1)
	End if

	var $space : Integer
	$space:=Position:C15(" "; $line)
	If ($space>0)
		return Substring:C12($line; 1; $space-1)
	End if

	return $line

Function _buildClassFunctionId($className : Text; $functionName : Text) : Text
	return $className+"::"+$functionName

Function _isClassHeaderLine($trimmed : Text) : Boolean
	If (This:C1470._startsWith($trimmed; "Class extends"))
		return True:C214
	End if

	If (This:C1470._startsWith($trimmed; "property "))
		return True:C214
	End if

	return False:C215

Function _isConstructorLine($trimmed : Text) : Boolean
	return This:C1470._startsWith($trimmed; "Class constructor")

Function _hasCoverageSkipAnnotation($code : Text) : Boolean
	var $lines : Collection
	$lines:=Split string:C1554($code; Char:C90(Carriage return:K15:38))
	If ($lines=Null:C1517)
		return False:C215
	End if

	var $limit : Integer
	If ($lines.length>10)
		$limit:=10
	Else 
		$limit:=$lines.length
	End if
	var $index : Integer
	For ($index; 0; $limit-1)
		var $trimmed : Text
		$trimmed:=This:C1470._trimLine($lines[$index])
		If ($trimmed="// #coverage: off") || ($trimmed="// #coverage: ignore") || ($trimmed="// #coverage: skip")
			return True:C214
		End if
	End for

	return False:C215

Function _collectHitsFromStorage() : Object
	var $hitsCopy : Object
	$hitsCopy:=New object:C1471

	Use (Storage:C1525)
		If (Storage:C1525.testCoverage#Null:C1517)
			Use (Storage:C1525.testCoverage)
				If (Storage:C1525.testCoverage.hits#Null:C1517)
					$hitsCopy:=OB Copy:C1225(Storage:C1525.testCoverage.hits)
				End if
			End use
		End if
	End use

	return $hitsCopy

Function _restoreInstrumentedCode()
	var $snapshot : Object
	For each ($snapshot; This:C1470.methodSnapshots)
		METHOD SET CODE($snapshot.methodPath; $snapshot.originalCode; *)
	End for each
	This:C1470.methodSnapshots.clear()

	If (This:C1470.coverageHelperExisted)
		If (This:C1470.coverageHelperOriginalCode#"")
			METHOD SET CODE(This:C1470.coverageRecordMethodName; This:C1470.coverageHelperOriginalCode; *)
		End if
	Else 
		METHOD SET CODE(This:C1470.coverageRecordMethodName; ""; *)
	End if

	This:C1470._deleteCreatedBackups()

Function _cleanupStorage()
	Use (Storage:C1525)
		If (Storage:C1525.testCoverage#Null:C1517)
			Use (Storage:C1525.testCoverage)
				Storage:C1525.testCoverage.hits:=New shared object:C1526
			End use
		End if
	End use

Function _deleteCreatedBackups()
	If (This:C1470.createdBackupFiles=Null:C1517)
		return
	End if

	var $file : 4D:C1709.File
	For each ($file; This:C1470.createdBackupFiles)
		If ($file#Null:C1517) && ($file.exists)
			$file.delete()
		End if
	End for each
	This:C1470.createdBackupFiles.clear()

Function _buildCoverageSummary($hits : Object) : Object
	var $summary : Object
	$summary:=New object:C1471("enabled"; This:C1470.enabled; "outputPath"; This:C1470.coverageOutputPath)
	var $totalMethods : Integer
	$totalMethods:=This:C1470.instrumentedMethods.length
	var $totalLines : Integer
	$totalLines:=0
	var $coveredMethods : Integer
	$coveredMethods:=0
	var $coveredLines : Integer
	$coveredLines:=0
	var $methodSummaries : Collection
	$methodSummaries:=New collection:C1472

	var $methodEntry : Object
	For each ($methodEntry; This:C1470.instrumentedMethods)
		var $lineNumbers : Collection
		$lineNumbers:=$methodEntry.lines
		$totalLines:=$totalLines+$lineNumbers.length
		var $methodHits : Object
		$methodHits:=($hits#Null:C1517) ? $hits[$methodEntry.methodId] : Null:C1517
		var $coveredCount : Integer
		$coveredCount:=0
		var $uncovered : Collection
		$uncovered:=New collection:C1472
		var $lineNumber : Integer
		For each ($lineNumber; $lineNumbers)
			var $lineKey : Text
			$lineKey:=String:C10($lineNumber)
			If ($methodHits#Null:C1517) && ($methodHits[$lineKey]=True:C214)
				$coveredCount:=$coveredCount+1
			Else 
				$uncovered.push($lineNumber)
			End if
		End for each
		If ($coveredCount>0)
			$coveredMethods:=$coveredMethods+1
		End if
		$coveredLines:=$coveredLines+$coveredCount
		var $coveragePercent : Real
		If ($lineNumbers.length>0)
			$coveragePercent:=($coveredCount/$lineNumbers.length)*100
		Else 
			$coveragePercent:=0
		End if
		methodSummaries.push(New object:C1471(\
			"id"; $methodEntry.methodId; \
			"displayName"; $methodEntry.displayName; \
			"totalLines"; $lineNumbers.length; \
			"coveredLines"; $coveredCount; \
			"coverage"; Round:C94($coveragePercent; 2); \
			"uncovered"; $uncovered; \
			"context"; $methodEntry.context; \
			"className"; $methodEntry.className || ""\
			))
	End for each

	var $methodCoverage : Real
	If ($totalMethods>0)
		$methodCoverage:=($coveredMethods/$totalMethods)*100
	Else 
		$methodCoverage:=0
	End if

	var $lineCoverage : Real
	If ($totalLines>0)
		$lineCoverage:=($coveredLines/$totalLines)*100
	Else 
		$lineCoverage:=0
	End if

	$summary.totalMethods:=$totalMethods
	$summary.coveredMethods:=$coveredMethods
	$summary.totalLines:=$totalLines
	$summary.coveredLines:=$coveredLines
	$summary.methodCoverage:=Round:C94($methodCoverage; 2)
	$summary.lineCoverage:=Round:C94($lineCoverage; 2)
	$summary.methods:=$methodSummaries

	return $summary

Function _writeCoverageReport($summary : Object)
	If ($summary=Null:C1517)
		return
	End if

	var $json : Text
	$json:=JSON Stringify:C1217($summary; *)
	var $file : 4D:C1709.File
	$file:=This:C1470.coverageOutputFolder.file("coverage.json")
	$file.setText($json; "UTF-8")
	This:C1470.coverageOutputPath:=$file.platformPath
	$summary.outputPath:=This:C1470.coverageOutputPath
	LOG EVENT:C667(Into system standard outputs:K38:9; "Coverage report written to: "+$file.platformPath+Char:C90(Carriage return:K15:38); Information message:K38:1)
