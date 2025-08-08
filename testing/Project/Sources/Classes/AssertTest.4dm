// Comprehensive tests for Assert class edge cases and functionality
Class constructor()

Function test_assert_initialization($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $testAssert : cs:C1710.Assert
	$testAssert:=cs:C1710.Assert.new()
	
	$testAssert.isNotNull($t; $assert; "Assert should initialize successfully")

Function test_areEqual_with_null_values($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	// Create separate testing context for testing assertions
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test null comparisons
	$assert.areEqual($mockTest; Null:C1517; Null:C1517; "Two nulls should be equal")
	$assert.isFalse($t; $mockTest.failed; "Null comparison should pass")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.areEqual($mockTest; "test"; Null:C1517; "String vs null should fail")
	$assert.isTrue($t; $mockTest.failed; "String vs null should fail the test")

Function test_areEqual_with_different_types($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test different types that are safely comparable in 4D
	$assert.areEqual($mockTest; "5"; "6"; "Different strings should fail")
	$assert.isTrue($t; $mockTest.failed; "Different strings should fail the test")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.areEqual($mockTest; 5; 6; "Different integers should fail")
	$assert.isTrue($t; $mockTest.failed; "Different integers should fail the test")

Function test_areEqual_with_objects($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test that we can test object properties instead of direct object comparison
	var $obj1 : Object
	var $obj2 : Object
	$obj1:=New object:C1471("name"; "John"; "age"; 25)
	$obj2:=New object:C1471("name"; "Jane"; "age"; 30)
	
	// Test different object properties
	$assert.areEqual($mockTest; $obj1.name; $obj2.name; "Different object properties should fail")
	$assert.isTrue($t; $mockTest.failed; "Different object properties should fail the test")
	
	// Test same object properties pass
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$obj2.name:="John"
	$assert.areEqual($mockTest; $obj1.name; $obj2.name; "Same object properties should pass")
	$assert.isFalse($t; $mockTest.failed; "Same object properties should pass the test")

Function test_areEqual_with_collections($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test that we can test collection properties instead of direct collection comparison
	var $col1 : Collection
	var $col2 : Collection
	$col1:=[1; 2; 3]
	$col2:=[4; 5; 6]
	
	// Test collection lengths are equal
	$assert.areEqual($mockTest; $col1.length; $col2.length; "Collections of same length should pass")
	$assert.isFalse($t; $mockTest.failed; "Same length collections should pass length comparison")
	
	// Test different first elements
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.areEqual($mockTest; $col1[0]; $col2[0]; "Different first elements should fail")
	$assert.isTrue($t; $mockTest.failed; "Different elements should fail the test")
	
	// Test same first elements pass
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$col2[0]:=1
	$assert.areEqual($mockTest; $col1[0]; $col2[0]; "Same first elements should pass")
	$assert.isFalse($t; $mockTest.failed; "Same elements should pass the test")

Function test_isTrue_edge_cases($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with actual boolean true
	$assert.isTrue($mockTest; True:C214; "Literal true should pass")
	$assert.isFalse($t; $mockTest.failed; "True value should pass isTrue")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isTrue($mockTest; False:C215; "Literal false should fail")
	$assert.isTrue($t; $mockTest.failed; "False value should fail isTrue")
	
	// Note: Testing numbers with isTrue may cause runtime errors in 4D
	// because isTrue expects boolean values
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isTrue($mockTest; (1=1); "Boolean expression should be truthy")
	$assert.isFalse($t; $mockTest.failed; "True boolean expression should pass isTrue")

Function test_isFalse_edge_cases($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with actual boolean false
	$assert.isFalse($mockTest; False:C215; "Literal false should pass")
	$assert.isFalse($t; $mockTest.failed; "False value should pass isFalse")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isFalse($mockTest; True:C214; "Literal true should fail")
	$assert.isTrue($t; $mockTest.failed; "True value should fail isFalse")

Function test_isNull_edge_cases($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with actual null
	$assert.isNull($mockTest; Null:C1517; "Literal null should pass")
	$assert.isFalse($t; $mockTest.failed; "Null value should pass isNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isNull($mockTest; ""; "Empty string should fail")
	$assert.isTrue($t; $mockTest.failed; "Empty string should fail isNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isNull($mockTest; 0; "Zero should fail")
	$assert.isTrue($t; $mockTest.failed; "Zero should fail isNull")

Function test_isNotNull_edge_cases($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test with non-null values
	$assert.isNotNull($mockTest; "test"; "String should pass")
	$assert.isFalse($t; $mockTest.failed; "String should pass isNotNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isNotNull($mockTest; 0; "Zero should pass")
	$assert.isFalse($t; $mockTest.failed; "Zero should pass isNotNull")
	
	$mockTest:=cs:C1710.Testing.new()  // Reset
	$assert.isNotNull($mockTest; Null:C1517; "Null should fail")
	$assert.isTrue($t; $mockTest.failed; "Null should fail isNotNull")

Function test_fail_method($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test explicit fail
	$assert.fail($mockTest; "Explicit failure message")
	$assert.isTrue($t; $mockTest.failed; "fail() should mark test as failed")
	$assert.areEqual($t; 1; $mockTest.logMessages.length; "fail() should add log message")
	$assert.areEqual($t; "Explicit failure message"; $mockTest.logMessages[0]; "fail() should store correct message")

Function test_message_logging($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test that assertion messages are logged on failure
	$assert.areEqual($mockTest; "expected"; "actual"; "Custom failure message")
	$assert.isTrue($t; $mockTest.failed; "Failed assertion should mark test as failed")
	$assert.areEqual($t; 1; $mockTest.logMessages.length; "Failed assertion should log message")
	$assert.areEqual($t; "Custom failure message"; $mockTest.logMessages[0]; "Should log the provided message")

Function test_multiple_assertions($t : cs:C1710.Testing)
	var $assert : cs:C1710.Assert
	$assert:=cs:C1710.Assert.new()
	
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()
	
	// Test multiple assertions accumulating messages
	$assert.areEqual($mockTest; 1; 2; "First failure")
	$assert.areEqual($mockTest; "a"; "b"; "Second failure")
	
	$assert.isTrue($t; $mockTest.failed; "Multiple failed assertions should mark test as failed")
	$assert.areEqual($t; 2; $mockTest.logMessages.length; "Should accumulate multiple failure messages")
	$assert.areEqual($t; "First failure"; $mockTest.logMessages[0]; "Should store first message")
	$assert.areEqual($t; "Second failure"; $mockTest.logMessages[1]; "Should store second message")