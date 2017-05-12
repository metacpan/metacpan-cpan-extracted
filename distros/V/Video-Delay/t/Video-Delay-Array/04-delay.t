# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Video::Delay::Array;

# Test.
my $obj = Video::Delay::Array->new(
	'array' => [10, 20],
	'loop' => 1,
);
my $ret = $obj->delay;
is($ret, 10, 'First item in array in loop mode.');
$ret = $obj->delay;
is($ret, 20, 'Second item in array in loop mode.');
$ret = $obj->delay;
is($ret, 10, 'First item in array in loop mode.');

# Test.
$obj = Video::Delay::Array->new(
	'array' => [10, 20],
	'loop' => 0,
);
$ret = $obj->delay;
is($ret, 10, 'First item in array in stright mode.');
$ret = $obj->delay;
is($ret, 20, 'Second item in array in stright mode.');
$ret = $obj->delay;
is($ret, undef, 'Undefined item in array in strigt mode.');
