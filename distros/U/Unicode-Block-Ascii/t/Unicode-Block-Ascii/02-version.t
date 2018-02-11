use strict;
use warnings;

use Unicode::Block::Ascii;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Unicode::Block::Ascii::VERSION, 0.03, 'Version.');
