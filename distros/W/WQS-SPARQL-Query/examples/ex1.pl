#!/usr/bin/env perl

use strict;
use warnings;

use WQS::SPARQL::Query::Select;

my $obj = WQS::SPARQL::Query::Select->new;

my $property = 'P957';
my $isbn = '80-239-7791-1';
my $sparql = $obj->select_value({$property => $isbn});

print "Property: $property\n";
print "ISBN: $isbn\n";
print "SPARQL:\n";
print $sparql;

# Output:
# Property: P957
# ISBN: 80-239-7791-1
# SPARQL:
# SELECT ?item WHERE {
#   ?item wdt:P957 '80-239-7791-1'.
# }