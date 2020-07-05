use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Tie::Hash::Check', 'Tie::Hash::Check is covered.');
