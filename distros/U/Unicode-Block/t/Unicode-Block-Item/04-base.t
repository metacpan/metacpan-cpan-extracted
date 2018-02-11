use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::Block::Item;

# Test.
my $obj = Unicode::Block::Item->new(
	'hex' => '0a',
);
my $ret = $obj->base;
is($ret, 'U+000x', "Get base for '0a'.");
