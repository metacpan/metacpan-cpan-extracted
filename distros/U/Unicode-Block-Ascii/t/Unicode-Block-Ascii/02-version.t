use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::Block::Ascii;

# Test.
is($Unicode::Block::Ascii::VERSION, 0.05, 'Version.');
