#!/usr/bin/perl
use lib '..';
require "Qtpl.pm";
$qtpl=new Template::Qtpl("ex1.xtpl");

print $qtpl->file_delim;

$qtpl->assign("VARIABLE","TEST"); # /* simple replace */
$qtpl->parse("main.block1");# 	/* parse block1 */
#$qtpl->parse("main.block2");#  /* uncomment to parse block2 */

# you can reference to array keys in the template file the following way:
#{DATA.ID} or {DATA.NAME} 
#say we have an array from a mysql query with the fields: ID, NAME, AGE
%row=(
		ID=>"38",
		NAME=>"cranx",
		AGE=>"20"
);

$qtpl->assign("DATA",\%row);
$qtpl->parse("main.block3"); #/* parse block3 */
$qtpl->parse("main");
$qtpl->out("main");
