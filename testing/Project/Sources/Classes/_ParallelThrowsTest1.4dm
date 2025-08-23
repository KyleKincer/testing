Class constructor()

Function test_throws_in_parallel($t : cs:C1710.Testing)
        var $op : 4D:C1709.Function
        $op:=Formula(UndefinedMethod())
        $t.assert.throws($t; $op)
