#!/usr/bin/env perl

use strict;
use warnings;

use WQS::SPARQL::Query::Count;

my $obj = WQS::SPARQL::Query::Count->new;

my $property = 'P957';
my $item = 'Q62098524';
my $sparql = $obj->count_item($property, $item);

print "Property: $property\n";
print "Item: $item\n";
print "SPARQL:\n";
print $sparql;

# Output:
# Property: P957
# ISBN: 80-239-7791-1
# SPARQL:
# SELECT (COUNT(?item) as ?count) WHERE {
#   ?item wdt:P957 wd:Q62098524
# }