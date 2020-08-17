use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Zodiac::Angle;

# Test.
my $obj = Zodiac::Angle->new;
my $ret = $obj->angle2zodiac(1.5);
is($ret, decode_utf8("1°♈30′"), 'Convert 1.5.');

# Test.
$ret = $obj->angle2zodiac(31.5);
is($ret, decode_utf8("1°♉30′"), 'Convert 31.5.');
