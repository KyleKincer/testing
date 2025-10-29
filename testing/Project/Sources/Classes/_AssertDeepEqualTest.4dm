// Comprehensive tests for Assert.areDeepEqual functionality
Class constructor()

Function test_areDeepEqual_simple_objects_equal($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={name: "John"; age: 30}
	$obj2:={name: "John"; age: 30}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Identical simple objects should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal objects should pass")

Function test_areDeepEqual_simple_objects_different_values($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={name: "John"; age: 30}
	$obj2:={name: "John"; age: 25}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Objects with different values should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different values should fail")

Function test_areDeepEqual_simple_objects_different_keys($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={name: "John"; age: 30}
	$obj2:={name: "John"; role: "admin"}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Objects with different keys should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different keys should fail")

Function test_areDeepEqual_simple_collections_equal($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[1; 2; 3; "test"]
	$col2:=[1; 2; 3; "test"]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Identical simple collections should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal collections should pass")

Function test_areDeepEqual_simple_collections_different_values($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[1; 2; 3]
	$col2:=[1; 2; 4]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Collections with different values should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different values should fail")

Function test_areDeepEqual_simple_collections_different_lengths($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[1; 2; 3]
	$col2:=[1; 2; 3; 4]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Collections with different lengths should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different lengths should fail")

Function test_areDeepEqual_nested_objects_equal($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={user: {name: "John"; age: 30}; role: "admin"}
	$obj2:={user: {name: "John"; age: 30}; role: "admin"}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Nested objects should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal nested objects should pass")

Function test_areDeepEqual_nested_objects_different($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={user: {name: "John"; age: 30}; role: "admin"}
	$obj2:={user: {name: "Jane"; age: 30}; role: "admin"}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Nested objects with different values should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different nested values should fail")

Function test_areDeepEqual_nested_collections_equal($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[[1; 2]; [3; 4]]
	$col2:=[[1; 2]; [3; 4]]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Nested collections should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal nested collections should pass")

Function test_areDeepEqual_nested_collections_different($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[[1; 2]; [3; 4]]
	$col2:=[[1; 2]; [3; 5]]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Nested collections with different values should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different nested values should fail")

Function test_areDeepEqual_mixed_nested_objects_with_collections($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={user: {name: "John"}; tags: ["admin"; "active"]}
	$obj2:={user: {name: "John"}; tags: ["admin"; "active"]}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Mixed nested structures should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal mixed structures should pass")

Function test_areDeepEqual_mixed_nested_collections_with_objects($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[{id: 1; name: "Item1"}; {id: 2; name: "Item2"}]
	$col2:=[{id: 1; name: "Item1"}; {id: 2; name: "Item2"}]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Collections with objects should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal mixed structures should pass")

Function test_areDeepEqual_deeply_nested_structures($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={level1: {level2: {level3: {data: "deep value"}}}}
	$obj2:={level1: {level2: {level3: {data: "deep value"}}}}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Deeply nested structures should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Equal deeply nested structures should pass")

Function test_areDeepEqual_circular_reference_objects($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={name: "circular"}
	$obj1.self:=$obj1  // Circular reference

	$obj2:={name: "circular"}
	$obj2.self:=$obj2  // Circular reference

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Circular objects should be handled")
	$t.assert.isFalse($t; $mockTest.failed; "Circular references should not cause infinite loop")

Function test_areDeepEqual_circular_reference_collections($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=["item1"]
	$col1.push($col1)  // Circular reference

	$col2:=["item1"]
	$col2.push($col2)  // Circular reference

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Circular collections should be handled")
	$t.assert.isFalse($t; $mockTest.failed; "Circular references should not cause infinite loop")

Function test_areDeepEqual_complex_circular_reference($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	var $child1; $child2 : Object

	$obj1:={name: "parent"}
	$child1:={name: "child"}
	$obj1.child:=$child1
	$child1.parent:=$obj1  // Circular reference through child

	$obj2:={name: "parent"}
	$child2:={name: "child"}
	$obj2.child:=$child2
	$child2.parent:=$obj2  // Circular reference through child

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Complex circular structures should be handled")
	$t.assert.isFalse($t; $mockTest.failed; "Complex circular references should pass")

Function test_areDeepEqual_null_objects($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:=Null:C1517
	$obj2:=Null:C1517

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Two null objects should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Null objects should be equal")

Function test_areDeepEqual_null_vs_object($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:=Null:C1517
	$obj2:={name: "test"}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Null vs object should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Null vs object should fail")

Function test_areDeepEqual_null_collections($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=Null:C1517
	$col2:=Null:C1517

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Two null collections should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Null collections should be equal")

Function test_areDeepEqual_null_vs_collection($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=Null:C1517
	$col2:=[1; 2; 3]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Null vs collection should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Null vs collection should fail")

Function test_areDeepEqual_empty_objects($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={}
	$obj2:={}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Empty objects should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Empty objects should pass")

Function test_areDeepEqual_empty_collections($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[]
	$col2:=[]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Empty collections should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Empty collections should pass")

Function test_areDeepEqual_empty_vs_non_empty_object($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={}
	$obj2:={key: "value"}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Empty vs non-empty object should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Empty vs non-empty should fail")

Function test_areDeepEqual_empty_vs_non_empty_collection($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[]
	$col2:=[1]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Empty vs non-empty collection should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Empty vs non-empty should fail")

Function test_areDeepEqual_primitives_equal($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	$t.assert.areDeepEqual($mockTest; "test"; "test"; "Equal strings should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Equal primitives should pass")

	$mockTest:=cs:C1710.Testing.new()
	$t.assert.areDeepEqual($mockTest; 42; 42; "Equal numbers should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Equal numbers should pass")

	$mockTest:=cs:C1710.Testing.new()
	$t.assert.areDeepEqual($mockTest; True:C214; True:C214; "Equal booleans should pass")
	$t.assert.isFalse($t; $mockTest.failed; "Equal booleans should pass")

Function test_areDeepEqual_primitives_different($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	$t.assert.areDeepEqual($mockTest; "test"; "different"; "Different strings should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different primitives should fail")

	$mockTest:=cs:C1710.Testing.new()
	$t.assert.areDeepEqual($mockTest; 42; 43; "Different numbers should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different numbers should fail")

Function test_areDeepEqual_different_types($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj : Object
	var $col : Collection
	$obj:={key: "value"}
	$col:=["value"]

	$t.assert.areDeepEqual($mockTest; $obj; $col; "Object vs collection should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different types should fail")

	$mockTest:=cs:C1710.Testing.new()
	$t.assert.areDeepEqual($mockTest; "42"; 42; "String vs number should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Different primitive types should fail")

Function test_areDeepEqual_object_with_undefined_properties($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={name: "John"; age: 30}
	$obj2:={name: "John"}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Objects with different property sets should fail")
	$t.assert.isTrue($t; $mockTest.failed; "Missing properties should fail")

Function test_areDeepEqual_objects_with_null_properties($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	$obj1:={name: "John"; age: Null:C1517}
	$obj2:={name: "John"; age: Null:C1517}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Objects with null properties should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Matching null properties should pass")

Function test_areDeepEqual_collections_with_null_elements($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $col1; $col2 : Collection
	$col1:=[1; Null:C1517; 3]
	$col2:=[1; Null:C1517; 3]

	$t.assert.areDeepEqual($mockTest; $col1; $col2; "Collections with null elements should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Matching null elements should pass")

Function test_areDeepEqual_complex_real_world_structure($t : cs:C1710.Testing)
	var $mockTest : cs:C1710.Testing
	$mockTest:=cs:C1710.Testing.new()

	var $obj1; $obj2 : Object
	// Simulate a real-world nested structure
	$obj1:={\
		user: {\
		id: 123; \
		name: "John Doe"; \
		email: "john@example.com"; \
		roles: ["admin"; "user"]; \
		metadata: {\
		created: "2024-01-01"; \
		tags: ["active"; "verified"]\
		}\
		}; \
		settings: {\
		theme: "dark"; \
		notifications: True:C214\
		}\
		}

	$obj2:={\
		user: {\
		id: 123; \
		name: "John Doe"; \
		email: "john@example.com"; \
		roles: ["admin"; "user"]; \
		metadata: {\
		created: "2024-01-01"; \
		tags: ["active"; "verified"]\
		}\
		}; \
		settings: {\
		theme: "dark"; \
		notifications: True:C214\
		}\
		}

	$t.assert.areDeepEqual($mockTest; $obj1; $obj2; "Complex real-world structures should be equal")
	$t.assert.isFalse($t; $mockTest.failed; "Matching complex structures should pass")
