#!/usr/local/bin/perl

unshift (@INC, "/manish-scripts/");
require ("sum.pl");
@numlist = <STDIN>;
chop (@numlist);
$total = &sum (@numlist);
print ("The total is $total.\n");



