# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Delay;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Delay::VERSION, 0.06, 'Version.');
