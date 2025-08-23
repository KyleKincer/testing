// Test class with a skipped test to verify skip functionality
Class constructor()

// #tags: unit, skip
Function test_should_be_skipped($t : cs:C1710.Testing)
        $t.assert.fail($t; "This test should be skipped and not executed")
