#!/usr/bin/perl
#		example 9
#		demonstrates parse blocks with ':'
#			saving parse order!
#
use lib '..';
require "Qtpl.pm";
$qtpl=new Template::Qtpl("ex9.xtpl");
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
		$qtpl->parse($_->{AGE}?"main.table.row:with_age":"main.table.row:without_age");
	}
	$qtpl->parse("main.table");
	$qtpl->parse("main");
	$qtpl->out("main");
