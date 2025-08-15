// Example test class that opts out of parallel execution
// #parallel: false

Class constructor()

Function test_database_intensive_operation($t : cs:C1710.Testing)
	// #tags: integration, slow
	
	// This test requires exclusive database access and should not run in parallel
	$t.log("Running database intensive operation that requires sequential execution")
	
	// Simulate database operation that requires isolation
	var $result : Integer
	$result:=1+1
	$t.assert.areEqual($t; 2; $result; "Simple calculation should work")

Function test_file_system_operation($t : cs:C1710.Testing)
	// #tags: integration, slow
	
	// This test modifies shared file system resources
	$t.log("Running file system operation that requires sequential execution")
	
	// Simulate file operation
	var $success : Boolean
	$success:=True:C214
	$t.assert.isTrue($t; $success; "File operation should succeed")