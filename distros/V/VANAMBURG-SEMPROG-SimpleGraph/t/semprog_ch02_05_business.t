#!perl -T
use strict;
use Test::More tests => 1;
use VANAMBURG::SEMPROG::SimpleGraph;
use Data::Dumper;

my $bg = VANAMBURG::SEMPROG::SimpleGraph->new();

$bg->load('data/business_triples.csv');


my @ibanks = map { $_->[0] } 
   $bg->triples(undef, 'industry', 'Investment Banking');

ok(23 == @ibanks, 'there are 23 investment banks');

diag(Dumper(@ibanks));
