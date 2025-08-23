// Tests for the new throws assertion
Class constructor()

Function test_throws_passes($t : cs:C1710.Testing)
        var $op : 4D:C1709.Function
        $op:=Formula(UndefinedMethod())
        $t.assert.throws($t; $op; "Should catch runtime error")

Function test_throws_fails_when_no_error($t : cs:C1710.Testing)
        var $mockTest : cs:C1710.Testing
        $mockTest:=cs:C1710.Testing.new()
        var $op : 4D:C1709.Function
        $op:=Formula(42)
        $mockTest.assert.throws($mockTest; $op)
        $t.assert.isTrue($t; $mockTest.failed; "throws should fail when no error occurs")
