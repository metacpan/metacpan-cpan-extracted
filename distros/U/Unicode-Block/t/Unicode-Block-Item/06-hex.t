use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::Block::Item;

# Test.
my $obj = Unicode::Block::Item->new(
	'hex' => '0a',
);
my $ret = $obj->hex;
is($ret, '000a', "Get hex number for '0a'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0000',
);
$ret = $obj->hex;
is($ret, '0000', "Get hex number for '0000'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0',
);
$ret = $obj->hex;
is($ret, '0000', "Get hex number for '0'.");
