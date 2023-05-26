use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query;

# Test.
is($WQS::SPARQL::Query::VERSION, 0.01, 'Version.');
