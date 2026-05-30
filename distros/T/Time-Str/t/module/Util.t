#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Util', qw[ lower_bound
                                range_bounds
                                upper_bound
                                valid_tzdb_timezone
                                valid_posix_timezone ]);
}

my @arr = (10, 20, 30, 40, 50);

## lower_bound

throws_ok { lower_bound() }
  qr/^Usage: lower_bound/,
  'lower_bound: no arguments';

throws_ok { lower_bound("not_a_ref", 10) }
  qr/must be an array reference/,
  'lower_bound: non-ref argument';

is(lower_bound(\@arr, 5), 0,
  'lower_bound: value below all');

is(lower_bound(\@arr, 10), 0,
  'lower_bound: matches first');

is(lower_bound(\@arr, 15), 1,
  'lower_bound: between 10 and 20');

is(lower_bound(\@arr, 25), 2,
  'lower_bound: between 20 and 30');

is(lower_bound(\@arr, 30), 2,
  'lower_bound: matches middle');

is(lower_bound(\@arr, 50), 4,
  'lower_bound: matches last');

is(lower_bound(\@arr, 55), 5,
  'lower_bound: value above all');

is(lower_bound(\@arr, 25, 1, 4), 2,
  'lower_bound: with lo/hi bounds');

is(lower_bound(\@arr, 5, 2, 5), 2,
  'lower_bound: value below search range');

is(lower_bound([], 10), 0,
  'lower_bound: empty array');

is(lower_bound([42], 41), 0,
  'lower_bound: single element, value below');

is(lower_bound([42], 42), 0,
  'lower_bound: single element, value equal');

is(lower_bound([42], 43), 1,
  'lower_bound: single element, value above');

# duplicates
{
  my @dup = (10, 20, 20, 20, 30);
  is(lower_bound(\@dup, 20), 1,
    'lower_bound: duplicates, finds first');
}

## upper_bound

throws_ok { upper_bound() }
  qr/^Usage: upper_bound/,
  'upper_bound: no arguments';

throws_ok { upper_bound("not_a_ref", 10) }
  qr/must be an array reference/,
  'upper_bound: non-ref argument';

is(upper_bound(\@arr, 5), 0,
  'upper_bound: value below all');

is(upper_bound(\@arr, 10), 1,
  'upper_bound: matches first');

is(upper_bound(\@arr, 15), 1,
  'upper_bound: between 10 and 20');

is(upper_bound(\@arr, 25), 2,
  'upper_bound: between 20 and 30');

is(upper_bound(\@arr, 30), 3,
  'upper_bound: matches middle');

is(upper_bound(\@arr, 50), 5,
  'upper_bound: matches last');

is(upper_bound(\@arr, 55), 5,
  'upper_bound: value above all');

is(upper_bound(\@arr, 30, 1, 4), 3,
  'upper_bound: with lo/hi bounds');

is(upper_bound(\@arr, 55, 2, 5), 5,
  'upper_bound: value above search range');

is(upper_bound([], 10), 0,
  'upper_bound: empty array');

is(upper_bound([42], 41), 0,
  'upper_bound: single element, value below');

is(upper_bound([42], 42), 1,
  'upper_bound: single element, value equal');

is(upper_bound([42], 43), 1,
  'upper_bound: single element, value above');

# duplicates
{
  my @dup = (10, 20, 20, 20, 30);
  is(upper_bound(\@dup, 20), 4,
    'upper_bound: duplicates, finds past last');
}

## lower_bound vs upper_bound relationship

# For unique values: lower_bound == upper_bound when value not in array
is(lower_bound(\@arr, 15), upper_bound(\@arr, 15),
  'lower == upper for non-matching value');

# For matching values: upper_bound = lower_bound + 1 (unique elements)
is(upper_bound(\@arr, 30), lower_bound(\@arr, 30) + 1,
  'upper = lower + 1 for matching unique value');

# For duplicates: upper - lower = count of matching elements
{
  my @dup = (10, 20, 20, 20, 30);
  is(upper_bound(\@dup, 20) - lower_bound(\@dup, 20), 3,
    'upper - lower = count of duplicates');
}

## range_bounds

throws_ok { range_bounds() }
  qr/^Usage: range_bounds/,
  'range_bounds: no arguments';

throws_ok { range_bounds("not_a_ref", 10, 20) }
  qr/must be an array reference/,
  'range_bounds: non-ref argument';

throws_ok { range_bounds(\@arr, 30, 20) }
  qr/Parameter 'min_value' must not exceed 'max_value'/,
  'range_bounds: min > max';

# basic range
{
  my ($lo, $hi) = range_bounds(\@arr, 15, 35);
  is($lo, 1, 'range_bounds: lo for [15, 35]');
  is($hi, 3, 'range_bounds: hi for [15, 35]');
}

# exact match on boundaries
{
  my ($lo, $hi) = range_bounds(\@arr, 20, 40);
  is($lo, 1, 'range_bounds: lo for [20, 40]');
  is($hi, 4, 'range_bounds: hi for [20, 40]');
}

# range covers all elements
{
  my ($lo, $hi) = range_bounds(\@arr, 5, 55);
  is($lo, 0, 'range_bounds: lo for full range');
  is($hi, 5, 'range_bounds: hi for full range');
}

# range below all elements
{
  my ($lo, $hi) = range_bounds(\@arr, 1, 5);
  is($lo, 0, 'range_bounds: lo for range below all');
  is($hi, 0, 'range_bounds: hi for range below all');
}

# range above all elements
{
  my ($lo, $hi) = range_bounds(\@arr, 55, 60);
  is($lo, 5, 'range_bounds: lo for range above all');
  is($hi, 5, 'range_bounds: hi for range above all');
}

# single element match
{
  my ($lo, $hi) = range_bounds(\@arr, 30, 30);
  is($lo, 2, 'range_bounds: lo for single value');
  is($hi, 3, 'range_bounds: hi for single value');
}

# no elements in range
{
  my ($lo, $hi) = range_bounds(\@arr, 21, 29);
  is($lo, 2, 'range_bounds: lo for gap range');
  is($hi, 2, 'range_bounds: hi for gap range');
}

# empty array
{
  my ($lo, $hi) = range_bounds([], 10, 20);
  is($lo, 0, 'range_bounds: lo for empty array');
  is($hi, 0, 'range_bounds: hi for empty array');
}

# duplicates
{
  my @dup = (10, 20, 20, 20, 30);
  my ($lo, $hi) = range_bounds(\@dup, 20, 20);
  is($lo, 1, 'range_bounds: lo for duplicates');
  is($hi, 4, 'range_bounds: hi for duplicates');
}

# consistency: range_bounds matches lower_bound + upper_bound
{
  my ($lo, $hi) = range_bounds(\@arr, 15, 35);
  is($lo, lower_bound(\@arr, 15), 'range_bounds: lo matches lower_bound');
  is($hi, upper_bound(\@arr, 35), 'range_bounds: hi matches upper_bound');
}

## negative values
{
  my @neg = (-50, -30, -10, 0, 10, 30);
  is(lower_bound(\@neg, -30), 1,
    'lower_bound: negative value match');
  is(upper_bound(\@neg, -30), 2,
    'upper_bound: negative value match');
  is(lower_bound(\@neg, -20), 2,
    'lower_bound: between negatives');
}

## valid_tzdb_timezone

throws_ok { valid_tzdb_timezone() }
  qr/^Usage: valid_tzdb_timezone/,
  'valid_tzdb_timezone: no arguments';

throws_ok { valid_tzdb_timezone('a', 'b') }
  qr/^Usage: valid_tzdb_timezone/,
  'valid_tzdb_timezone: too many arguments';

# valid names
ok(valid_tzdb_timezone('UTC'),
  'valid_tzdb_timezone: UTC');

ok(valid_tzdb_timezone('EST'),
  'valid_tzdb_timezone: EST');

ok(valid_tzdb_timezone('America/New_York'),
  'valid_tzdb_timezone: America/New_York');

ok(valid_tzdb_timezone('Europe/Stockholm'),
  'valid_tzdb_timezone: Europe/Stockholm');

ok(valid_tzdb_timezone('America/Argentina/Buenos_Aires'),
  'valid_tzdb_timezone: three-level path');

ok(valid_tzdb_timezone('Etc/GMT+5'),
  'valid_tzdb_timezone: Etc/GMT+5');

ok(valid_tzdb_timezone('Etc/GMT-14'),
  'valid_tzdb_timezone: Etc/GMT-14');

ok(valid_tzdb_timezone('US/Eastern'),
  'valid_tzdb_timezone: US/Eastern');

ok(valid_tzdb_timezone('Pacific/Port_Moresby'),
  'valid_tzdb_timezone: underscore in component');

ok(valid_tzdb_timezone('America/North_Dakota/New_Salem'),
  'valid_tzdb_timezone: three-level with underscores');

ok(valid_tzdb_timezone('Asia/Ho_Chi_Minh'),
  'valid_tzdb_timezone: multiple underscores');

ok(valid_tzdb_timezone('Factory'),
  'valid_tzdb_timezone: Factory');

# invalid names
ok(!valid_tzdb_timezone(undef),
  'valid_tzdb_timezone: undef');

ok(!valid_tzdb_timezone(''),
  'valid_tzdb_timezone: empty string');

ok(!valid_tzdb_timezone('123'),
  'valid_tzdb_timezone: starts with digit');

ok(!valid_tzdb_timezone('/America/New_York'),
  'valid_tzdb_timezone: leading slash');

ok(!valid_tzdb_timezone('America/New_York/'),
  'valid_tzdb_timezone: trailing slash');

ok(!valid_tzdb_timezone('America//New_York'),
  'valid_tzdb_timezone: double slash');

ok(!valid_tzdb_timezone('America/New York'),
  'valid_tzdb_timezone: space in name');

ok(!valid_tzdb_timezone('America/New_York '),
  'valid_tzdb_timezone: trailing space');

ok(!valid_tzdb_timezone('_America/New_York'),
  'valid_tzdb_timezone: leading underscore');

ok(!valid_tzdb_timezone('America/_New_York'),
  'valid_tzdb_timezone: component starts with underscore');

ok(!valid_tzdb_timezone('America/1York'),
  'valid_tzdb_timezone: component starts with digit');

## valid_posix_timezone

throws_ok { valid_posix_timezone() }
  qr/^Usage: valid_posix_timezone/,
  'valid_posix_timezone: no arguments';

throws_ok { valid_posix_timezone('a', 'b') }
  qr/^Usage: valid_posix_timezone/,
  'valid_posix_timezone: too many arguments';

# valid strings — fixed offset (no DST)
ok(valid_posix_timezone('UTC0'),
  'valid_posix_timezone: UTC0');

ok(valid_posix_timezone('EST5'),
  'valid_posix_timezone: EST5');

ok(valid_posix_timezone('CET-1'),
  'valid_posix_timezone: CET-1');

ok(valid_posix_timezone('IST-5:30'),
  'valid_posix_timezone: offset with minutes');

ok(valid_posix_timezone('NPT-5:45:00'),
  'valid_posix_timezone: offset with seconds');

# valid strings — with DST and M rules
ok(valid_posix_timezone('EST5EDT,M3.2.0,M11.1.0'),
  'valid_posix_timezone: US Eastern');

ok(valid_posix_timezone('CET-1CEST,M3.5.0/2,M10.5.0/3'),
  'valid_posix_timezone: Central European');

ok(valid_posix_timezone('NZST-12NZDT,M9.5.0,M4.1.0/3'),
  'valid_posix_timezone: New Zealand');

ok(valid_posix_timezone('EST5EDT4,M3.2.0,M11.1.0'),
  'valid_posix_timezone: explicit DST offset');

ok(valid_posix_timezone('CST6CDT,M3.2.0/2:00,M11.1.0/2:00'),
  'valid_posix_timezone: rule times with minutes');

# valid strings — J and n rule forms
ok(valid_posix_timezone('EST5EDT,J80,J310'),
  'valid_posix_timezone: Julian day rules');

ok(valid_posix_timezone('EST5EDT,60,305'),
  'valid_posix_timezone: zero-based day rules');

# valid strings — negative rule times
ok(valid_posix_timezone('EST5EDT,M3.2.0/-1,M11.1.0'),
  'valid_posix_timezone: negative rule time');

# valid strings — positive offset sign
ok(valid_posix_timezone('ABC+5'),
  'valid_posix_timezone: positive offset sign');

# invalid strings
ok(!valid_posix_timezone(undef),
  'valid_posix_timezone: undef');

ok(!valid_posix_timezone(''),
  'valid_posix_timezone: empty string');

ok(!valid_posix_timezone('E5'),
  'valid_posix_timezone: name too short (1 char)');

ok(!valid_posix_timezone('ES5'),
  'valid_posix_timezone: name too short (2 chars)');

ok(!valid_posix_timezone('EST'),
  'valid_posix_timezone: missing offset');

ok(!valid_posix_timezone('123'),
  'valid_posix_timezone: numeric only');

ok(!valid_posix_timezone('EST5EDT'),
  'valid_posix_timezone: DST name without rules');

ok(!valid_posix_timezone('EST5EDT,M3.2.0'),
  'valid_posix_timezone: only one rule');

ok(!valid_posix_timezone('<+05>-5'),
  'valid_posix_timezone: quoted name (not POSIX)');

ok(!valid_posix_timezone('EST5EDT,M3.2.0,M11.1.0,M12.1.0'),
  'valid_posix_timezone: too many rules');

ok(!valid_posix_timezone(' EST5'),
  'valid_posix_timezone: leading space');

ok(!valid_posix_timezone('EST5 '),
  'valid_posix_timezone: trailing space');

done_testing;
