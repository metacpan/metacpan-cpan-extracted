use strict;
use warnings;

use Video::Delay::Const;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Delay::Const::VERSION, 0.07, 'Version.');
