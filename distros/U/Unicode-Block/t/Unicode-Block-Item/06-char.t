# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::Block::Item;

# Test.
my $obj = Unicode::Block::Item->new(
	'hex' => '2661',
);
my $ret = $obj->char;
is($ret, decode_utf8('♡'), "Get unicode character for '2661'.");

# Test.
$ret = $obj->char;
is($ret, decode_utf8('♡'), "Get unicode character for '2661' again.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '1018F',
);
$ret = $obj->char;
is($ret, ' ', 'Get unicode character for 1018C, which is unasigned.');

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0300',
);
$ret = $obj->char;
is($ret, decode_utf8(' ̀'),
	'Get unicode character for 0300, which is \'Non-Spacing Mark\'.');

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0488',
);
$ret = $obj->char;
is($ret, decode_utf8(' ҈'),
	'Get unicode character for 0488, which is \'Enclosing Mark\'.');
