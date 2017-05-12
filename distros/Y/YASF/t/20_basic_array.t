#!/usr/bin/perl

# Basic tests on interpolating against array references

use 5.008;
use strict;
use warnings;

use Test::More;

use YASF;

my $master_data = [ 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 ];

plan tests => 6;

my ($str, $data);

# Basic instantiation has already been tested. At this point, we assume that
# creating the objects works correctly.

$str = YASF->new('1={8} 2={7} 3={6}');

# Basic substitution with explicit data
is($str % $master_data, '1=1 2=2 3=3', 'Basic % substitution');
is($str->format($master_data), '1=1 2=2 3=3', 'Basic format() substitution');

# Basic substitution with bound data
$str->bind($master_data);
is($str->format, '1=1 2=2 3=3', 'format() substitution with bindings');
is($str, '1=1 2=2 3=3', 'Direct stringification');

# With bound data, verify that explicit data overrides the bound data:
$data = [ 0 .. 9 ];
is($str % $data, '1=8 2=7 3=6', 'Basic %, with override data');
is($str->format($data), '1=8 2=7 3=6', 'Basic format with overrides');

exit;
