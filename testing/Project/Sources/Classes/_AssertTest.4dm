// Comprehensive tests for Assert class edge cases and functionality
Class constructor()

Function test_assert_initialization($t : cs:C1710.Testing)
	$t.assert.isNotNull($t; $t.assert; "Assert should initialize successfully")

Function test_areEqual_with_null_values($t : cs:C1710.Testing)
	// Create separate testing context for testing assertions
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test null comparisons
	$t.assert.areEqual($mockTest; Null:C1517; Null:C1517; "Two nulls should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Null comparison should pass")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.areEqual($mockTest; "test"; Null:C1517; "String vs null should fail")
	$t.assert.isTrue($t; $mockTest.failed; "String vs null should fail the test")

Function test_areEqual_with_different_types($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test different types that are safely comparable in 4D
	$t.assert.areEqual($mockTest; "5"; "6"; "Different strings should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different strings should fail the test")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.areEqual($mockTest; 5; 6; "Different integers should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different integers should fail the test")

Function test_areEqual_with_objects($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test that we can test object properties instead of direct object comparison
	var $obj1 : Object
	var $obj2 : Object
	$obj1:=New object:C1471("name"; "John"; "age"; 25)
	$obj2:=New object:C1471("name"; "Jane"; "age"; 30)
	
	// Test different object properties
	$t.assert.areEqual($mockTest; $obj1.name; $obj2.name; "Different object properties should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different object properties should fail the test")
	
	// Test same object properties pass
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$obj2.name:="John"
	$t.assert.areEqual($mockTest; $obj1.name; $obj2.name; "Same object properties should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Same object properties should pass the test")

Function test_areEqual_with_collections($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test that we can test collection properties instead of direct collection comparison
	var $col1 : Collection
	var $col2 : Collection
	$col1:=[1; 2; 3]
	$col2:=[4; 5; 6]
	
	// Test collection lengths are equal
	$t.assert.areEqual($mockTest; $col1.length; $col2.length; "Collections of same length should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Same length collections should pass length comparison")
	
	// Test different first elements
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.areEqual($mockTest; $col1[0]; $col2[0]; "Different first elements should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different elements should fail the test")
	
	// Test same first elements pass
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$col2[0]:=1
	$t.assert.areEqual($mockTest; $col1[0]; $col2[0]; "Same first elements should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Same elements should pass the test")

Function test_isTrue_edge_cases($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with actual boolean true
	$t.assert.isTrue($mockTest; True:C214; "Literal true should pass")
	$t.assert.isFalse($t; $mockTest.failed; "True value should pass isTrue")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isTrue($mockTest; False:C215; "Literal false should fail")
	$t.assert.isTrue($t; $mockTest.failed; "False value should fail isTrue")
	
	// Note: Testing numbers with isTrue may cause runtime errors in 4D
	// because isTrue expects boolean values
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isTrue($mockTest; (1=1); "Boolean expression should be truthy")
	$t.assert.isFalse($t; $mockTest.failed; "True boolean expression should pass isTrue")

Function test_isFalse_edge_cases($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with actual boolean false
	$t.assert.isFalse($mockTest; False:C215; "Literal false should pass")
	$t.assert.isFalse($t; $mockTest.failed; "False value should pass isFalse")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isFalse($mockTest; True:C214; "Literal true should fail")
	$t.assert.isTrue($t; $mockTest.failed; "True value should fail isFalse")

Function test_isNull_edge_cases($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with actual null
	$t.assert.isNull($mockTest; Null:C1517; "Literal null should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Null value should pass isNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isNull($mockTest; ""; "Empty string should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Empty string should fail isNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isNull($mockTest; 0; "Zero should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Zero should fail isNull")

Function test_isNotNull_edge_cases($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with non-null values
	$t.assert.isNotNull($mockTest; "test"; "String should pass")
	$t.assert.isFalse($t; $mockTest.failed; "String should pass isNotNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isNotNull($mockTest; 0; "Zero should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Zero should pass isNotNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$t.assert.isNotNull($mockTest; Null:C1517; "Null should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Null should fail isNotNull")

Function test_fail_method($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test explicit fail
	$t.assert.fail($mockTest; "Explicit failure message")
	$t.assert.isTrue($t; $mockTest.failed; "fail() should mark test as failed")
	$t.assert.areEqual($t; 1; $mockTest.logMessages.length; "fail() should add log message")
	$t.assert.areEqual($t; "Explicit failure message"; $mockTest.logMessages[0]; "fail() should store correct message")

Function test_message_logging($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test that assertion messages are logged on failure
	$t.assert.areEqual($mockTest; "expected"; "actual"; "Custom failure message")
	$t.assert.isTrue($t; $mockTest.failed; "Failed assertion should mark test as failed")
	$t.assert.areEqual($t; 1; $mockTest.logMessages.length; "Failed assertion should log message")
	$t.assert.areEqual($t; "Custom failure message"; $mockTest.logMessages[0]; "Should log the provided message")

Function test_multiple_assertions($t : cs:C1710.Testing)
        var $mockTest : cs:C1710.Testing
        $mockTest:=cs:C1710.Testing.new()
	
	// Test multiple assertions accumulating messages
	$t.assert.areEqual($mockTest; 1; 2; "First failure")
	$t.assert.areEqual($mockTest; "a"; "b"; "Second failure")
	
        $t.assert.isTrue($t; $mockTest.failed; "Multiple failed assertions should mark test as failed")
        $t.assert.areEqual($t; 2; $mockTest.logMessages.length; "Should accumulate multiple failure messages")
        $t.assert.areEqual($t; "First failure"; $mockTest.logMessages[0]; "Should store first message")
        $t.assert.areEqual($t; "Second failure"; $mockTest.logMessages[1]; "Should store second message")

Function test_contains_with_text($t : cs:C1710.Testing)
        var $mockTest : cs:C1710.Testing
        $mockTest:=cs:C1710.Testing.new()

        // Successful text containment
        $t.assert.contains($mockTest; "hello world"; "world"; "Should find substring")
        $t.assert.isFalse($t; $mockTest.failed; "Valid substring should pass")

        // Failing text containment
        $mockTest:=cs:C1710.Testing.new()
        $t.assert.contains($mockTest; "hello"; "world"; "Missing substring should fail")
        $t.assert.isTrue($t; $mockTest.failed; "Missing substring should fail")

Function test_contains_with_collection($t : cs:C1710.Testing)
        var $mockTest : cs:C1710.Testing
        $mockTest:=cs:C1710.Testing.new()

        var $col : Collection
        $col:=["a"; "b"; "c"]

        // Successful collection containment
        $t.assert.contains($mockTest; $col; "b"; "Should find element in collection")
        $t.assert.isFalse($t; $mockTest.failed; "Existing element should pass")

        // Failing collection containment
        $mockTest:=cs:C1710.Testing.new()
        $t.assert.contains($mockTest; $col; "d"; "Missing element should fail")
        $t.assert.isTrue($t; $mockTest.failed; "Missing element should fail")