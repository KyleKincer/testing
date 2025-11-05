//%attributes = {"shared":true}
/* Run tests with the given class store (cs), Storage reference, and optional user parameters
In order to run tests from a host project with this component, you must:
1. Pass in the host project's class store (cs) so the component has access to host classes
2. Pass in the host project's Storage object so triggers can check the testMode flag
3. Optionally pass in user parameters object (e.g., New object("triggers"; "enabled"))
*/
#DECLARE($cs : 4D:C1709.Object; $hostStorage : 4D:C1709.Object; $userParams : 4D:C1709.Object)

var $coverageManager : cs:C1710.CoverageManager
$coverageManager:=cs:C1710.CoverageManager.new($cs; $hostStorage; $userParams)

var $coverageEnabled : Boolean
$coverageEnabled:=$coverageManager.enable()

var $runner : cs:C1710.TestRunner
// Pass user params to TestRunner (it will initialize trigger control based on params)
$runner:=cs:C1710.TestRunner.new($cs; $hostStorage; $userParams)

$runner.run()

If ($coverageEnabled)
	$coverageManager.finalize($runner.getResults())
End if