#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Time', qw[ timegm_posix
                                timegm_modern
                                valid_hms
                                valid_hms60 ]);
}

## valid_hms

throws_ok { valid_hms() }
  qr/^Usage: valid_hms/, 'valid_hms: no arguments';

ok( valid_hms( 0,  0,  0), 'valid_hms: 00:00:00');
ok( valid_hms(12, 30, 45), 'valid_hms: 12:30:45');
ok( valid_hms(23, 59, 59), 'valid_hms: 23:59:59');

ok( valid_hms( 0,  0,  0), 'valid_hms: min boundary');
ok( valid_hms(23, 59, 59), 'valid_hms: max boundary');

ok(!valid_hms(-1,  0,  0), 'valid_hms: hour -1');
ok(!valid_hms(24,  0,  0), 'valid_hms: hour 24');
ok(!valid_hms( 0, -1,  0), 'valid_hms: minute -1');
ok(!valid_hms( 0, 60,  0), 'valid_hms: minute 60');
ok(!valid_hms( 0,  0, -1), 'valid_hms: second -1');
ok(!valid_hms( 0,  0, 60), 'valid_hms: second 60');

## valid_hms60

throws_ok { valid_hms60() }
  qr/^Usage: valid_hms60/,
  'valid_hms60: no arguments';

ok( valid_hms60( 0,  0,  0), 'valid_hms60: 00:00:00');
ok( valid_hms60(23, 59, 59), 'valid_hms60: 23:59:59');
ok( valid_hms60(23, 59, 60), 'valid_hms60: 23:59:60 (leap second)');

ok(!valid_hms60(-1,  0,  0), 'valid_hms60: hour -1');
ok(!valid_hms60(24,  0,  0), 'valid_hms60: hour 24');
ok(!valid_hms60( 0, -1,  0), 'valid_hms60: minute -1');
ok(!valid_hms60( 0, 60,  0), 'valid_hms60: minute 60');
ok(!valid_hms60( 0,  0, -1), 'valid_hms60: second -1');
ok(!valid_hms60( 0,  0, 61), 'valid_hms60: second 61');

## timegm_modern

throws_ok { timegm_modern() }
  qr/^Usage: timegm_modern/,
  'timegm_modern: no arguments';

is(timegm_modern(0, 0, 0, 1, 1, 1970), 0,
  'timegm_modern: 1970-01-01T00:00:00Z = epoch 0');

is(timegm_modern(1, 0, 0, 1, 1, 1970), 1,
  'timegm_modern: 1970-01-01T00:00:01Z');

is(timegm_modern(59, 59, 23, 31, 12, 1969), -1,
  'timegm_modern: 1969-12-31T23:59:59Z');

# well-known dates
is(timegm_modern(0, 0, 0, 1, 1, 2000), 946684800,
  'timegm_modern: 2000-01-01T00:00:00Z');

is(timegm_modern(0, 0, 12, 24, 12, 2024), 1735041600,
  'timegm_modern: 2024-12-24T12:00:00Z');

is(timegm_modern(40, 17, 20, 20, 7, 1969), -14182940,
  'timegm_modern: 1969-07-20T20:17:40Z (Apollo 11)');

# Y2K38 boundary
is(timegm_modern(7, 14, 3, 19, 1, 2038), 2147483647,
  'timegm_modern: 2038-01-19T03:14:07Z (max signed 32-bit)');

is(timegm_modern(8, 14, 3, 19, 1, 2038), 2147483648,
  'timegm_modern: 2038-01-19T03:14:08Z (32-bit overflow)');

# year range boundaries
is(timegm_modern(0, 0, 0, 1, 1, 1), -62135596800,
  'timegm_modern: 0001-01-01T00:00:00Z');

is(timegm_modern(59, 59, 23, 31, 12, 9999), 253402300799,
  'timegm_modern: 9999-12-31T23:59:59Z');

# leap year
is(timegm_modern(0, 0, 0, 29, 2, 2024), timegm_modern(0, 0, 0, 1, 3, 2024) - 86400,
  'timegm_modern: Feb 29 leap year');

# consecutive days
is(timegm_modern(0, 0, 0, 2, 1, 2024) - timegm_modern(0, 0, 0, 1, 1, 2024), 86400,
  'timegm_modern: consecutive days = 86400 seconds');

# parameter validation
throws_ok { timegm_modern(0, 0, 0, 1, 1, 0) }
  qr/Parameter 'year' is out of range/,
  'timegm_modern: year 0';

throws_ok { timegm_modern(0, 0, 0, 1, 1, 10000) }
  qr/Parameter 'year' is out of range/,
  'timegm_modern: year 10000';

throws_ok { timegm_modern(0, 0, 0, 1, 0, 2024) }
  qr/Parameter 'month' is out of range/,
  'timegm_modern: month 0';

throws_ok { timegm_modern(0, 0, 0, 1, 13, 2024) }
  qr/Parameter 'month' is out of range/,
  'timegm_modern: month 13';

throws_ok { timegm_modern(0, 0, 0, 0, 1, 2024) }
  qr/Parameter 'day' is out of range/,
  'timegm_modern: day 0';

throws_ok { timegm_modern(0, 0, 0, 32, 1, 2024) }
  qr/Parameter 'day' is out of range/,
  'timegm_modern: day 32 for January';

throws_ok { timegm_modern(0, 0, 0, 29, 2, 2023) }
  qr/Parameter 'day' is out of range/,
  'timegm_modern: Feb 29 non-leap year';

throws_ok { timegm_modern(0, 0, 24, 1, 1, 2024) }
  qr/Parameter 'hour' is out of range/,
  'timegm_modern: hour 24';

throws_ok { timegm_modern(0, 60, 0, 1, 1, 2024) }
  qr/Parameter 'minute' is out of range/,
  'timegm_modern: minute 60';

throws_ok { timegm_modern(60, 0, 0, 1, 1, 2024) }
  qr/Parameter 'second' is out of range/,
  'timegm_modern: second 60';

## timegm_posix

throws_ok { timegm_posix() }
  qr/^Usage: timegm_posix/,
  'timegm_posix: no arguments';

# Unix epoch: year=70 (since 1900), month=0 (January)
is(timegm_posix(0, 0, 0, 1, 0, 70), 0,
  'timegm_posix: epoch 0');

# Equivalence with timegm_modern
is(timegm_posix(0, 0, 12, 24, 11, 124), timegm_modern(0, 0, 12, 24, 12, 2024),
  'timegm_posix: matches timegm_modern for 2024-12-24');

is(timegm_posix(59, 59, 23, 31, 11, 124), timegm_modern(59, 59, 23, 31, 12, 2024),
  'timegm_posix: matches timegm_modern for 2024-12-31T23:59:59');

# year range boundaries (posix convention)
is(timegm_posix(0, 0, 0, 1, 0, -1899), timegm_modern(0, 0, 0, 1, 1, 1),
  'timegm_posix: year 1 (posix: -1899)');

is(timegm_posix(59, 59, 23, 31, 11, 8099), timegm_modern(59, 59, 23, 31, 12, 9999),
  'timegm_posix: year 9999 (posix: 8099)');

# parameter validation
throws_ok { timegm_posix(0, 0, 0, 1, -1, 70) }
  qr/Parameter 'month' is out of range/,
  'timegm_posix: month -1 (posix)';

throws_ok { timegm_posix(0, 0, 0, 1, 12, 70) }
  qr/Parameter 'month' is out of range/,
  'timegm_posix: month 12 (posix)';

done_testing;
