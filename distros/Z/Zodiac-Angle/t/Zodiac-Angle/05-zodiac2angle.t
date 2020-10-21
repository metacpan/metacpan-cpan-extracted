use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Zodiac::Angle;

# Test.
SKIP: {
	skip 'No implemented.', 1;
my $obj = Zodiac::Angle->new;
my $ret = $obj->zodiac2angle(decode_utf8("1°♈30′"));
is($ret, 1.5, decode_utf8('Convert 1°♈30′.'));
};
