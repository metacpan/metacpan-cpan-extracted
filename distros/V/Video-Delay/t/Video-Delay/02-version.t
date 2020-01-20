use strict;
use warnings;

use Video::Delay;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Delay::VERSION, 0.07, 'Version.');
