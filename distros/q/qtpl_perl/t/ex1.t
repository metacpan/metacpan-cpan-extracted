
#		example 1
#		demonstrates basic template functions
#		-simple replaces ( {VARIABLE1}, and {DATA.ID} {DATA.NAME} {DATA.AGE} )
#		-dynamic blocks
#
#		$Id: ex1.t,v 1.2 2001/10/18 09:39:24 alexey_pres Exp $

BEGIN { $| = 1; print "1..2\n"; }       
END {print "not ok 1\n" unless $loaded;}

use Qtpl;
$qtpl=new Template::Qtpl("ex/ex1.xtpl");
$loaded = 1;
print "ok 1\n"; #loaded
	
$qtpl->assign("VARIABLE","TEST"); #/* simple replace */

$qtpl->parse("main.block1");	#/* parse block1 */
$qtpl->parse("main.block2"); #/* uncomment to parse block2 */

#you can reference to array keys in the template file the following way:
#	{DATA.ID} or {DATA.NAME} 
#say we have an array from a mysql query with the fields: ID, NAME, AGE
%row=(
	ID=>"38",
	NAME=>"cranx",
	AGE=>"20"
);
$qtpl->assign("DATA",\%row);
$qtpl->parse("main.block3");
$qtpl->parse("main");
#$qtpl->out("main");
print "ok 2\n"
