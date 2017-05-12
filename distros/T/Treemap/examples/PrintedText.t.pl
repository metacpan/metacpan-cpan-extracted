#!/usr/bin/perl

use lib( ".." );
use Data::Dumper;
use Treemap::Output::PrintedText;

$output = new Treemap::Output::PrintedText;

$output->rect(0,0,10,10);
$output->rect(0,0,10,10);
$output->text("level2");
$output->text("level1");

1;
