use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Toolforge::MixNMatch::Print;

# Test.
is($Toolforge::MixNMatch::Print::VERSION, 0.03, 'Version.');
