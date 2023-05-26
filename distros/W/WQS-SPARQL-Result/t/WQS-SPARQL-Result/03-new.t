use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Result;

# Test.
my $obj = WQS::SPARQL::Result->new;
isa_ok($obj, 'WQS::SPARQL::Result');
