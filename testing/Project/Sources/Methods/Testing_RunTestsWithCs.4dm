//%attributes = {"shared":true}
/* Run tests with the given class store (cs)
In order to run test from a host project with this component, you must
pass in the host project's class store (cs) so that the component has
access to the host project's classes.
*/
#DECLARE($cs : 4D:C1709.Object)

var $runner : cs:C1710.TestRunner
$runner:=cs:C1710.TestRunner.new($cs)

$runner.run()