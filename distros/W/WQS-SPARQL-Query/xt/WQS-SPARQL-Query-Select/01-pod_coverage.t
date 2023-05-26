use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('WQS::SPARQL::Query::Select', 'WQS::SPARQL::Query::Select is covered.');
