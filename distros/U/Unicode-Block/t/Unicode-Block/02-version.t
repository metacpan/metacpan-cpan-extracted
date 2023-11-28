use strict;
use warnings;

use Unicode::Block;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Unicode::Block::VERSION, 0.08, 'Version.');
