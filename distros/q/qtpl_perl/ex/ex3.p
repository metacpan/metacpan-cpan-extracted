#!/usr/bin/perl
#		example 3
#		autoreset
use lib '..';
require "Qtpl.pm";

$qtpl=new Template::Qtpl ("ex3.xtpl");
#	this is the code from example 2:
	@rows=(
			{
				ID=>"38",
				NAME=>"cranx",
             	AGE=>"20"
			},
			{
				ID=>"27",
				NAME=>"ozsvar",
				AGE=>"34"
			},
			{
				ID=>"56",
				NAME=>"alpi",
				AGE=>"23"
			}
    );
	
	for ($i=0;$i<=2;$i++) {
		$qtpl->assign("DATA",$rows[$i]);	#	/* assign array data */
		$qtpl->assign("ROW_NR",$i);
		$qtpl->parse("main.table.row");	#		/* parse a row */
	}
	
	$qtpl->parse("main.table");			#		/* parse the table */

#	now, if you wanted to parse the table once again with the old rows,
#	and put one more $qtpl->parse("main.table") line, it wouldn't do it
#	becuase the sub-blocks were resetted (normal operation)
#   to parse the same block two or more times without having the sub-blocks resetted,
#	you should use clear_autoreset();
#	to switch back call set_autoreset();
	
	$qtpl->clear_autoreset();
	for ($i=0;$i<=2;$i++) {
		$qtpl->assign("DATA",$rows[$i]);	#	/* assign array data */
		$qtpl->assign("ROW_NR",$i);
		$qtpl->parse("main.table.row");		#	/* parse a row */
	}
	
	$qtpl->parse("main.table");			#		/* parse the table */
	$qtpl->parse("main.table");			#		/* parse it one more time.. wihtout clearing the rows (sub-block reset) */

	$qtpl->parse("main");
	$qtpl->out("main");
