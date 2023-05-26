use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query::Count;

# Test.
my $obj = WQS::SPARQL::Query::Count->new;
isa_ok($obj, 'WQS::SPARQL::Query::Count');
