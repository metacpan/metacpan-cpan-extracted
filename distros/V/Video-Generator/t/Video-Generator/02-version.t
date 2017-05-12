# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Generator::VERSION, 0.08, 'Version.');
