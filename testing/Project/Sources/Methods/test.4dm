//%attributes = {}
If (Application info:C1599.headless)
	var $runner : cs:C1710.TestRunner
	$runner:=cs:C1710.TestRunner.new()
	$runner.run()
	
	If (Application type:C494#6)
		QUIT 4D:C291
	End if 
	
Else 
	$runner:=cs:C1710.TestRunner.new()
	$runner.run()
End if 