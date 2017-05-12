#!/usr/bin/perl

use Text::Spintax;
use YAML;
use strict;

my $node = Text::Spintax->new->parse("This is nested {{very|quite} deeply|deep}.");
$node->equal_path_weight;
my %count;
foreach (1 .. 1000) {
   $count{$node->render}++;
}
print Dump(\%count);
