#!/usr/bin/perl
#		example 4
#		demonstrates recursive parse
use lib '..';
require "Qtpl.pm";

$qtpl=new Template::Qtpl("ex4.xtpl");
$qtpl->rparse("main");
$qtpl->out("main");
