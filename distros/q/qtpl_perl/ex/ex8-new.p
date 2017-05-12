#!/usr/bin/perl
#		example 2
#		demonstrates multiple level dynamic blocks
use lib '..';
require "Qtpl.pm";
$qtpl=new Template::Qtpl("ex8.xtpl");
#/* you can reference to hash keys in the template file the following way:
#{DATA.ID} or {DATA.NAME} 
#say we have an array from a mysql query with the following fields: ID, NAME, AGE
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
				NAME=>"alpi"
			}
    );
	$i = 0;	
	foreach (@rows) {
		$i++;
		$qtpl->assign("DATA",$_);
		$qtpl->assign("ROW_NR",$i);
		$qtpl->parse("main.table.row");
	}
	$qtpl->parse("main.table");
	print $qtpl->text("main.table.row");
	$qtpl->parse("main");
	$qtpl->out("main");
