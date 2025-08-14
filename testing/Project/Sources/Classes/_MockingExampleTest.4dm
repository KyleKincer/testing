// Example test demonstrating UnitStatsTracker for mocking
// Simplified version compatible with 4D Formula limitations

Class constructor()

Function test_mock_basic_functionality($t : cs:C1710.Testing)
	// Test the mock functionality directly
	var $result : Variant
	$result:=$t.stats.mock("testFunction"; ["param1"; "param2"]; "mock_result")
	
	// Verify the mock was called correctly
	var $stat : cs:C1710._UnitStatsDetail
	$stat:=$t.stats.getStat("testFunction")
	
	$t.assert.areEqual($t; 1; $stat.getNumberOfCalls(); "Mock should be called once")
	$t.assert.areEqual($t; "param1"; $stat.getXCallYParameter(1; 1); "First parameter should be param1")
	$t.assert.areEqual($t; "param2"; $stat.getXCallYParameter(1; 2); "Second parameter should be param2")
	$t.assert.areEqual($t; "mock_result"; $result; "Mock should return expected result")

Function test_mock_multiple_calls($t : cs:C1710.Testing)
	// Make multiple calls to the same mock
	$t.stats.mock("validateUser"; ["admin"]; True:C214)
	$t.stats.mock("validateUser"; ["guest"]; False:C215)
	
	// Verify both calls were tracked
	var $stat : cs:C1710._UnitStatsDetail
	$stat:=$t.stats.getStat("validateUser")
	
	$t.assert.areEqual($t; 2; $stat.getNumberOfCalls(); "Should be called twice")
	$t.assert.areEqual($t; "admin"; $stat.getXCallYParameter(1; 1); "First call should be admin")
	$t.assert.areEqual($t; "guest"; $stat.getXCallYParameter(2; 1); "Second call should be guest")

Function test_mock_with_collections($t : cs:C1710.Testing)
	// Test mocking with collection parameters
	var $testCollection : Collection
	$testCollection:=["item1"; "item2"; "item3"]
	
	$t.stats.mock("processCollection"; [$testCollection]; "processed")
	
	// Verify collection parameter was captured
	var $stat : cs:C1710._UnitStatsDetail
	$stat:=$t.stats.getStat("processCollection")
	
	$t.assert.areEqual($t; 1; $stat.getNumberOfCalls(); "Should be called once")
	
	var $capturedCollection : Collection
	$capturedCollection:=$stat.getXCallYParameter(1; 1)
	$t.assert.areEqual($t; 3; $capturedCollection.length; "Collection should have 3 items")
	$t.assert.areEqual($t; "item1"; $capturedCollection[0]; "First item should be item1")

Function test_mock_statistics_reset($t : cs:C1710.Testing)
	// Make some mock calls
	$t.stats.mock("testMethod"; ["param"]; "result")
	$t.stats.mock("testMethod"; ["param2"]; "result2")
	
	var $stat : cs:C1710._UnitStatsDetail
	$stat:=$t.stats.getStat("testMethod")
	$t.assert.areEqual($t; 2; $stat.getNumberOfCalls(); "Should have 2 calls before reset")
	
	// Reset statistics
	$t.stats.resetStatistics()
	
	// Verify reset worked
	$stat:=$t.stats.getStat("testMethod")
	$t.assert.areEqual($t; 0; $stat.getNumberOfCalls(); "Should have 0 calls after reset")

Function test_mock_parameter_details($t : cs:C1710.Testing)
	// Test with object parameters
	var $params : Collection
	$params:=["GET"; "/api/endpoint"; New object:C1471("timeout"; 5000; "retries"; 3)]
	
	$t.stats.mock("apiCall"; $params; New object:C1471("status"; 200; "data"; "success"))
	
	// Verify parameter details
	var $stat : cs:C1710._UnitStatsDetail
	$stat:=$t.stats.getStat("apiCall")
	
	$t.assert.areEqual($t; 1; $stat.getNumberOfCalls(); "Should be called once")
	$t.assert.areEqual($t; 3; $stat.getXCallParamLength(1); "Should have 3 parameters")
	$t.assert.areEqual($t; "GET"; $stat.getXCallYParameter(1; 1); "First parameter should be GET")
	$t.assert.areEqual($t; "/api/endpoint"; $stat.getXCallYParameter(1; 2); "Second parameter should be endpoint")
	
	var $options : Object
	$options:=$stat.getXCallYParameter(1; 3)
	$t.assert.areEqual($t; 5000; $options.timeout; "Timeout should be 5000")
	$t.assert.areEqual($t; 3; $options.retries; "Retries should be 3")