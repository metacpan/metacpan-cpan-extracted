#!/usr/bin/perl
#		example 6
#		demonstrates nullblocks
use lib '..';
require "Qtpl.pm";
$qtpl=new Template::Qtpl("ex6.xtpl");

$qtpl->assign(INTRO_TEXT,"what happens if we don't parse the subblocks?");
$qtpl->parse("main.block");

$qtpl->assign(INTRO_TEXT,"what happens if we parse them? :)");
$qtpl->parse("main.block.subblock1");
$qtpl->parse("main.block.subblock2");
$qtpl->parse("main.block");

$qtpl->assign(INTRO_TEXT,"ok.. SetNullBlock(\"block not parsed!\") coming");
$qtpl->SetNullBlock("block not parsed!");
$qtpl->parse("main.block");

$qtpl->assign(INTRO_TEXT,"ok.. custom nullblocks.. SetNullBlock(\"subblock1 not parsed!\",\"main.block.subblock1\")");
$qtpl->SetNullBlock("block not parsed!");
$qtpl->SetNullBlock("subblock1 not parsed!","main.block.subblock1");
$qtpl->parse("main.block");

$qtpl->parse("main");
$qtpl->out("main");
