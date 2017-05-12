# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Delay::Array;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Delay::Array::VERSION, 0.06, 'Version.');
