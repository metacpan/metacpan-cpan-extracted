# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Delay::Const;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Delay::Const::VERSION, 0.06, 'Version.');
