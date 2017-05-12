# Pragmas.
use strict;
use warnings;

# Modules.
use Unicode::Block::Ascii;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Unicode::Block::Ascii::VERSION, 0.01, 'Version.');
