# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Pattern;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Video::Pattern::VERSION, 0.08, 'Version.');
