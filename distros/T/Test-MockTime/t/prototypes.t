#! /usr/bin/perl 
use Test::MockTime ':all';
use Test::More tests => 3;
use strict;
use warnings;

set_fixed_time(2);
my $four = time + 2;
is($four, 4, "time() does not try so slurp any arguments");

my @arr    = (0, 1, 2);
my $got    = localtime @arr;
my $expect = localtime scalar @arr;
is($got, $expect, "localtime() treats its argument as an expression");

$got    = gmtime @arr;
$expect = gmtime scalar @arr;
is($got, $expect, "gmtime() treats its argument as an expression");
