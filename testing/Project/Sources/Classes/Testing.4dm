// Acts as the test context

property failed : Boolean
property done : Boolean
property logMessages : Collection
property assertions : Collection
property assert : cs:C1710.Assert
property stats : cs:C1710.UnitStatsTracker
property failureCallChain : Collection
property classInstance : 4D:C1709.Object

Class constructor()
	This:C1470.failed:=False:C215
	This:C1470.done:=False:C215
        This:C1470.logMessages:=[]
        This:C1470.assertions:=[]
        This:C1470.assert:=cs:C1710.Assert.new()
        This:C1470.stats:=cs:C1710.UnitStatsTracker.new()
        This:C1470.failureCallChain:=Null
	
Function log($message : Text)
	This:C1470.logMessages.push($message)
	
Function fail()
	This:C1470.failed:=True:C214
	// Capture call chain when test fails for debugging
	This:C1470.failureCallChain:=Call chain:C1662
	
Function fatal()
	This:C1470.failed:=True:C214
	This:C1470.done:=True:C214
	// Capture call chain when test fails fatally for debugging
	This:C1470.failureCallChain:=Call chain:C1662
	
Function resetForNewTest()
	This:C1470.failed:=False:C215
	This:C1470.done:=False:C215
        This:C1470.logMessages:=[]
        This:C1470.assertions:=[]
        This:C1470.stats.resetStatistics()
        This:C1470.failureCallChain:=Null
	
Function run($name : Text; $subtest : 4D:C1709.Function; $data : Variant) : Boolean
        // Execute a named subtest with its own Testing context
        // Returns true if the subtest passed

        var $subT : cs:C1710.Testing
        $subT:=cs:C1710.Testing.new()

       // Share assertion object with parent but keep stats isolated
       $subT.assert:=This:C1470.assert
       $subT.classInstance:=This:C1470.classInstance

        var $result : Boolean
        $result:=True:C214

        // Allow calling run with no subtest for compatibility
        If ($subtest=Null:C1517)
                return $result
        End if

        // Execute the subtest with the parent test context
        var $context : 4D:C1709.Object
        $context:=This:C1470.classInstance
        If ($context=Null:C1517)
                $context:=This:C1470
        End if

        var $args : Collection
        $args:=[$subT]
        If (Count parameters>=3)
                $args.push($data)
        End if
        $subtest.apply($context; $args)

        // Propagate log messages with subtest name prefix
        var $message : Text
        For each ($message; $subT.logMessages)
                This:C1470.log($name+": "+$message)
        End for each

        // If the subtest failed, mark parent as failed and capture call chain
        If ($subT.failed)
                This:C1470.fail()
                If ($subT.failureCallChain#Null)
                        This:C1470.failureCallChain:=$subT.failureCallChain
                End if
                $result:=False:C215
        End if

        return $result

// Transaction management methods for manual control

Function startTransaction() : Boolean
	// Start a transaction and return success status
	START TRANSACTION:C239
	return True

Function validateTransaction() : Boolean
	// Validate the current transaction
	VALIDATE TRANSACTION:C240
	return (OK=1)

Function cancelTransaction()
	// Cancel the current transaction
	CANCEL TRANSACTION:C241

Function inTransaction() : Boolean
	// Check if we're currently in a transaction
	return (In transaction:C397)

Function withTransaction($operation : 4D:C1709.Function) : Boolean
	// Execute an operation within a transaction
	// Returns true if operation succeeded and transaction was validated
	var $success : Boolean
	$success:=False
	
	START TRANSACTION:C239
	
	// Set up error handler to catch any errors during operation
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	$operation.apply()
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
	// Check if operation succeeded (no test failures)
	If (Not:C34(This:C1470.failed))
		CANCEL TRANSACTION:C241  // Always rollback for withTransaction
		$success:=True
	Else 
		CANCEL TRANSACTION:C241
		$success:=False
	End if 
	
	return $success

Function withTransactionValidate($operation : 4D:C1709.Function) : Boolean
	// Execute an operation within a transaction and always validate on success
	// Useful for tests that need to persist data
	var $success : Boolean
	$success:=False
	
	START TRANSACTION:C239
	
	// Set up error handler to catch any errors during operation
	var $previousErrorHandler : Text
	$previousErrorHandler:=Method called on error:C704
	ON ERR CALL:C155("TestErrorHandler")
	
	$operation.apply()
	
	// Restore previous error handler
	If ($previousErrorHandler#"")
		ON ERR CALL:C155($previousErrorHandler)
	Else 
		ON ERR CALL:C155("")
	End if 
	
	// Validate transaction if test succeeded
	If (Not:C34(This:C1470.failed))
		VALIDATE TRANSACTION:C240
		$success:=(OK=1)
	Else 
		CANCEL TRANSACTION:C241
		$success:=False
	End if 
	
	return $success

Function formatCallChain() : Text
	// Format the call chain into a readable string for debugging
	var $result : Text
	var $i : Integer
	var $callInfo : Object
	
	$result:=""
	
	If (This:C1470.failureCallChain#Null)
		$result:="Call Stack:\n"
		
		For ($i; 0; This:C1470.failureCallChain.length-1)
			$callInfo:=This:C1470.failureCallChain[$i]
			$result:=$result+"  "+String:C10($i+1)+". "
			
			If ($callInfo.name#Null)
				$result:=$result+$callInfo.name
			Else 
				$result:=$result+"<unnamed>"
			End if 
			
			If ($callInfo.type#Null)
				$result:=$result+" ("+$callInfo.type+")"
			End if 
			
			If ($callInfo.line#Null)
				$result:=$result+" at line "+String:C10($callInfo.line)
			End if 
			
			If ($callInfo.database#Null)
				$result:=$result+" in "+$callInfo.database
			End if 
			
			$result:=$result+"\n"
		End for 
	End if 
	
	return $result
	
