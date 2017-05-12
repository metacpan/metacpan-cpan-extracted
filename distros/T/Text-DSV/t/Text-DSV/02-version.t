# Pragmas.
use strict;
use warnings;

# Modules.
use Text::DSV;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Text::DSV::VERSION, 0.1, 'Version.');
