// Example tests demonstrating the tagging system
Class constructor()

// #tags: unit, fast
Function test_basic_addition($t : cs:C1710.Testing)
	$t.assert.areEqual($t; 4; 2+2; "Basic addition should work")

// #tags: integration, slow
Function test_database_connection($t : cs:C1710.Testing)
	// Simulate a slow database operation
	DELAY PROCESS:C323(Current process:C322; 10)  // 10 ticks = ~167ms
	$t.assert.isTrue($t; True:C214; "Database connection test")

// #tags: unit, edge-case
Function test_empty_string_handling($t : cs:C1710.Testing)
	var $result : Text
	$result:=""+"test"
	$t.assert.areEqual($t; "test"; $result; "Empty string concatenation")

// #tags: integration, performance
Function test_large_collection_processing($t : cs:C1710.Testing)
	var $collection : Collection
	$collection:=[]
	var $i : Integer
	For ($i; 1; 1000)
		$collection.push($i)
	End for 
	
	$t.assert.areEqual($t; 1000; $collection.length; "Large collection should have correct size")

// #tags: unit, validation
Function test_parameter_validation($t : cs:C1710.Testing)
	// Test null parameter handling
	var $result : Boolean
	$result:=(Null:C1517=Null:C1517)
	$t.assert.isTrue($t; $result; "Null comparison should work")

// #tags: integration, external, no-linux
Function test_file_system_access($t : cs:C1710.Testing)
	// Test file system access
	var $folder : 4D:C1709.Folder
	$folder:=Folder:C1567(fk desktop folder:K87:19)
	$t.assert.isNotNull($t; $folder; "Should be able to access desktop folder")
        $t.assert.isTrue($t; $folder.exists; "Desktop folder should exist")
