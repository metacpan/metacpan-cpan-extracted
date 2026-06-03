#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str', qw[str2time str2date]);
}

# A leap second (23:59:60 UTC) cannot be represented as a POSIX time, so
# str2time folds it onto the preceding 23:59:59 and validates that it
# lands on a real leap-second slot. The check is table-free (permissive):
# every June 30 and December 31 since 1972 is accepted, whether or not a
# leap second was actually inserted on that day.

## str2date parses :60 permissively (no position constraint)

{
  my %d = str2date('2016-12-31T23:59:60Z');
  is($d{second}, 60, 'str2date: end-of-year leap second parses');

  %d = str2date('2015-06-30T23:59:60Z');
  is($d{second}, 60, 'str2date: mid-year leap second parses');

  %d = str2date('2017-01-01T00:59:60+01:00');
  is($d{second}, 60, 'str2date: leap second with offset parses');

  # Permissive: any HH:MM:60 parses; str2time does the real validation
  %d = str2date('2024-06-15T12:30:60Z');
  is($d{second}, 60, 'str2date: noon :60 parses (validated later by str2time)');
}

## str2time folds a leap second onto 23:59:59

{
  is(str2time('2016-12-31T23:59:60Z'), 1483228799,
    'str2time: 2016-12-31 leap second folds to 23:59:59');

  is(str2time('2016-12-31T23:59:60Z'), str2time('2016-12-31T23:59:59Z'),
    'str2time: leap second and 23:59:59 share the same POSIX time');

  is(str2time('2015-06-30T23:59:60Z'), 1435708799,
    'str2time: 2015-06-30 mid-year leap second');

  is(str2time('1990-12-31T23:59:60Z'), 662687999,
    'str2time: 1990-12-31 leap second');
}

## A leap second is the same UTC instant regardless of the offset used

{
  is(str2time('2017-01-01T00:59:60+01:00'), str2time('2016-12-31T23:59:60Z'),
    'str2time: leap second via +01:00 resolves to 23:59:60 UTC');

  is(str2time('1990-12-31T15:59:60-08:00'), str2time('1990-12-31T23:59:60Z'),
    'str2time: leap second via -08:00 resolves to 23:59:60 UTC');
}

## Table-free: a valid slot with no actual leap second is still accepted

{
  is(str2time('1973-06-30T23:59:60Z'), 110332799,
    'str2time: accepts a leap-second slot with no historical leap second');
}

## Fractional leap second

{
  is(str2time('2016-12-31T23:59:60.5Z'), 1483228799.5,
    'str2time: fractional leap second keeps its fraction');
}

## Invalid: leap second not at 23:59:60 UTC

{
  throws_ok { str2time('2024-06-15T12:30:60Z') }
    qr/^Unable to convert: a leap second must occur at 23:59:60 UTC/,
    'str2time: rejects :60 at noon';

  # 23:59:60+01:00 is 22:59:60 UTC, not on the slot
  throws_ok { str2time('2016-12-31T23:59:60+01:00') }
    qr/^Unable to convert: a leap second must occur at 23:59:60 UTC/,
    'str2time: rejects offset that shifts off 23:59:60 UTC';
}

## Invalid: 23:59:60 UTC on a non-leap-second date

{
  throws_ok { str2time('2024-03-31T23:59:60Z') }
    qr/^Unable to convert: no leap second on this UTC date/,
    'str2time: rejects 23:59:60 on March 31';

  throws_ok { str2time('2016-01-01T23:59:60Z') }
    qr/^Unable to convert: no leap second on this UTC date/,
    'str2time: rejects 23:59:60 on January 1';

  throws_ok { str2time('1970-12-31T23:59:60Z') }
    qr/^Unable to convert: no leap second on this UTC date/,
    'str2time: rejects leap second before 1972';
}

done_testing;
