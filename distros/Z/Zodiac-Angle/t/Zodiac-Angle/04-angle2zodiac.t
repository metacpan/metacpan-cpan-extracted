use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 21;
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

# Test.
$ret = $obj->angle2zodiac(61.5);
is($ret, decode_utf8("1°♊30′"), 'Convert 61.5.');

# Test.
$ret = $obj->angle2zodiac(91.5);
is($ret, decode_utf8("1°♋30′"), 'Convert 91.5.');

# Test.
$ret = $obj->angle2zodiac(121.5);
is($ret, decode_utf8("1°♌30′"), 'Convert 121.5.');

# Test.
$ret = $obj->angle2zodiac(151.5);
is($ret, decode_utf8("1°♍30′"), 'Convert 151.5.');

# Test.
$ret = $obj->angle2zodiac(181.5);
is($ret, decode_utf8("1°♎30′"), 'Convert 181.5.');

# Test.
$ret = $obj->angle2zodiac(211.5);
is($ret, decode_utf8("1°♏30′"), 'Convert 211.5.');

# Test.
$ret = $obj->angle2zodiac(241.5);
is($ret, decode_utf8("1°♐30′"), 'Convert 241.5.');

# Test.
$ret = $obj->angle2zodiac(271.5);
is($ret, decode_utf8("1°♑30′"), 'Convert 271.5.');

# Test.
$ret = $obj->angle2zodiac(301.5);
is($ret, decode_utf8("1°♒30′"), 'Convert 301.5.');

# Test.
$ret = $obj->angle2zodiac(331.5);
is($ret, decode_utf8("1°♓30′"), 'Convert 331.5.');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 1,
	'second' => 1,
});
is($ret, decode_utf8("27°♏48′24.0909′′"),
	'Convert value of 237.8066919028 to output with minute and seconds.');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 1,
});
is($ret, decode_utf8("27°♏48′"),
	'Convert value of 237.8066919028 to output with minute.');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 0,
});
is($ret, decode_utf8("27°♏"),
	'Convert value of 237.8066919028 to output with degrees only.');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 1,
	'second' => 1,
	'sign_type' => 'ascii',
});
is($ret, decode_utf8("27 sc 48'24.0909''"),
	'Convert value of 237.8066919028 to output with minute and seconds (ascii output).');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 1,
	'second' => 1,
	'second_round' => 2,
	'sign_type' => 'ascii',
});
is($ret, decode_utf8("27 sc 48'24.09''"),
	'Convert value of 237.8066919028 to output with minute and seconds rounded to 2 decimals (ascii output).');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 1,
	'second' => 0,
	'sign_type' => 'ascii',
});
is($ret, decode_utf8("27 sc 48'"),
	'Convert value of 237.8066919028 to output with minute (ascii output).');

# Test.
$ret = $obj->angle2zodiac(237.8066919028, {
	'minute' => 0,
	'sign_type' => 'ascii',
});
is($ret, decode_utf8("27 sc"),
	'Convert value of 237.8066919028 to output without minute and seconds (ascii output).');

# Test.
eval {
	$obj->angle2zodiac(237.8066919028, {
		'sign_type' => 'foo',
	});
};
is($EVAL_ERROR, "Parameter 'sign_type' is bad. Possible values are 'sign', 'ascii' and 'struct'.\n",
	"Parameter 'sign_type' is bad.");
clean();
