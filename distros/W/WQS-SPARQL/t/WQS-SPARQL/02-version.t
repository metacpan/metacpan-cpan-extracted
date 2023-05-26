use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL;

# Test.
is($WQS::SPARQL::VERSION, 0.01, 'Version.');
