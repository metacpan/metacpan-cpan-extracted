use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query::Count;

# Test.
is($WQS::SPARQL::Query::Count::VERSION, 0.03, 'Version.');
