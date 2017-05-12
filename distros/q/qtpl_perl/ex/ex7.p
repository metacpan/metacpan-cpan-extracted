#!/usr/bin/perl
#		example 7
#		demonstrates file includes
use lib '..';
require "Qtpl.pm";
$qtpl=new Template::Qtpl ("ex7.xtpl");

$qtpl->assign(FILENAME,"ex7-inc.xtpl");
$qtpl->rparse("main.inc");

$qtpl->parse("main");
$qtpl->out("main");
