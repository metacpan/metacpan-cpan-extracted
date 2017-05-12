# Pragmas.
use strict;
use warnings;

# Modules.
use Unicode::Block::List;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Unicode::Block::List::VERSION, 0.02, 'Version.');
