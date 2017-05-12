#!/usr/bin/perl
#		example 5
#		demonstrates nullstrings
use lib '..';
require "Qtpl.pm";

$qtpl=new Template::Qtpl("ex5.xtpl");

$qtpl->assign(INTRO_TEXT,"by default, if some variables weren't assigned a value, they simply disappear from the parsed html:");	
$qtpl->parse("main.form");

$qtpl->assign(INTRO_TEXT,"ok, now let's assign a nullstring:");	
$qtpl->SetNullString("value not specified!");
$qtpl->parse("main.form");

$qtpl->assign(INTRO_TEXT,"custom nullstring for a specific variable and default nullstring mixed:");	
$qtpl->SetNullString("no value..");
$qtpl->SetNullString("no email specified!",EMAIL);
$qtpl->parse("main.form");

$qtpl->assign(INTRO_TEXT,"custom nullstring for every variable:) .. you should get it by now. :P");	
$qtpl->SetNullString("no email specified",EMAIL);
$qtpl->SetNullString("no name specified",FULLNAME);
$qtpl->SetNullString("no income?",INCOME);
$qtpl->parse("main.form");

$qtpl->parse("main");
$qtpl->out("main");
