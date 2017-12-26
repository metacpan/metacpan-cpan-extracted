use strict;
use warnings;

use Unicode::Block::Item;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Unicode::Block::Item::VERSION, 0.06, 'Version.');
