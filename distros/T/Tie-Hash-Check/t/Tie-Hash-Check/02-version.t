use strict;
use warnings;

use Tie::Hash::Check;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tie::Hash::Check::VERSION, 0.09, 'Version.');
