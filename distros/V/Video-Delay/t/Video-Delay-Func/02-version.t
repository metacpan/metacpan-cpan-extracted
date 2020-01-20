use strict;
use warnings;

use Video::Delay::Func;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Delay::Func::VERSION, 0.07, 'Version.');
