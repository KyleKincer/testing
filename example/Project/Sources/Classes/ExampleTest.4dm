Class constructor()

Function test_areEqual_pass($t : cs.Testing)
	var $assert : cs.Assert
	$assert:=cs.Assert.new()
	$assert.areEqual($t; 42; 40+2; "areEqual should pass when values are equal")

Function test_isTrue_pass($t : cs.Testing)
	var $assert : cs.Assert
	$assert:=cs.Assert.new()
	$assert.isTrue($t; (1<2); "isTrue should pass for true condition")

Function test_isFalse_pass($t : cs.Testing)
	var $assert : cs.Assert
	$assert:=cs.Assert.new()
	$assert.isFalse($t; (2<1); "isFalse should pass for false condition")

Function test_isNull_pass($t : cs.Testing)
	var $assert : cs.Assert
	$assert:=cs.Assert.new()
	$assert.isNull($t; Null; "isNull should pass when value is Null")

Function test_isNotNull_pass($t : cs.Testing)
	var $assert : cs.Assert
	$assert:=cs.Assert.new()
	$assert.isNotNull($t; "value"; "isNotNull should pass when value is not Null")


