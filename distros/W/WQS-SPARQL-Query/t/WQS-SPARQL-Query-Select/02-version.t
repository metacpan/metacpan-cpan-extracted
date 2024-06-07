use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query::Select;

# Test.
is($WQS::SPARQL::Query::Select::VERSION, 0.03, 'Version.');
