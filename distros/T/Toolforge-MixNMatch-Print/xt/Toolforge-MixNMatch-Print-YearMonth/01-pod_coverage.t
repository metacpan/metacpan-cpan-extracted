use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Toolforge::MixNMatch::Print::YearMonth', 'Toolforge::MixNMatch::Print::YearMonth is covered.');
