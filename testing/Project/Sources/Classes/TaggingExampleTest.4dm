// Example tests demonstrating the tagging system
Class constructor()

// #tags: unit, fast
Function test_basic_addition($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	$assert.areEqual($t; 4; 2+2; "Basic addition should work")

// #tags: integration, slow
Function test_database_connection($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Simulate a slow database operation
	DELAY PROCESS:C323(Current process:C322; 10)  // 10 ticks = ~167ms
	$assert.isTrue($t; True:C214; "Database connection test")

// #tags: unit, edge-case
Function test_empty_string_handling($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $result : Text
	$result:=""+"test"
	$assert.areEqual($t; "test"; $result; "Empty string concatenation")

// #tags: integration, performance
Function test_large_collection_processing($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $collection : Collection
	$collection:=[]
	var $i : Integer
	For ($i; 1; 1000)
		$collection.push($i)
	End for 
	
	$assert.areEqual($t; 1000; $collection.length; "Large collection should have correct size")

// #tags: unit, validation
Function test_parameter_validation($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test null parameter handling
	var $result : Boolean
	$result:=(Null:C1517=Null:C1517)
	$assert.isTrue($t; $result; "Null comparison should work")

// #tags: integration, external
Function test_file_system_access($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Test file system access
	var $folder : 4D:C1709.Folder
	$folder:=Folder:C1567(fk desktop folder:K87:19)
	$assert.isNotNull($t; $folder; "Should be able to access desktop folder")
	$assert.isTrue($t; $folder.exists; "Desktop folder should exist")