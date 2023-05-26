use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query::Select;

# Test.
my $obj = WQS::SPARQL::Query::Select->new;
isa_ok($obj, 'WQS::SPARQL::Query::Select');
