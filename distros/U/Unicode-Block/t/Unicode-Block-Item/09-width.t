# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Unicode::Block::Item;

# Test.
my $obj = Unicode::Block::Item->new(
	'hex' => '0a',
);
my $ret = $obj->width;
is($ret, '1', "Get width for '0a'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '3111',
);
$ret = $obj->width;
is($ret, '2', "Get width for '3111'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '1018F',
);
$ret = $obj->width;
is($ret, 1, "Get width for '1018C', which is unasigned.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0488',
);
$ret = $obj->width;
is($ret, 1, "Get width for '0488', which is \'Enclosing Mark\'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0300',
);
$ret = $obj->width;
is($ret, 1, "Get width for '0300', which is \'Non-Spacing Mark\'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '1106d',
);
$ret = $obj->width;
is($ret, 1, "Get width for '1106d'.");

# Test.
$ret = $obj->width;
is($ret, 1, "Get width for '1106d' again.");
