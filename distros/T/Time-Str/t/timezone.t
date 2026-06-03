#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str', qw[str2time]);
  use_ok('Time::TZif::POSIX');
}

# str2time accepts a 'timezone' object (anything that can('offset_for_local'))
# to resolve a timestamp that carries no UTC designator or numeric offset:
# the parsed fields are treated as local wall-clock time and converted to
# UTC via the object. A string that already carries an offset is converted
# with that offset; the object is only consulted as a fallback.
#
# Central European Time: UTC+1 (CET) in winter, UTC+2 (CEST) in summer,
# DST from the last Sunday of March 02:00 to the last Sunday of October 03:00.
my $TZ_STRING = 'CET-1CEST,M3.5.0/2,M10.5.0/3';

sub tz {
  Time::TZif::POSIX->new(tz_string => $TZ_STRING, @_);
}

## Parameter validation

{
  throws_ok { str2time('2021-01-15T12:00:00', format => 'ISO8601', timezone => undef) }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_local' method/,
    'timezone: undef is rejected';

  throws_ok { str2time('2021-01-15T12:00:00', format => 'ISO8601', timezone => 'CET') }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_local' method/,
    'timezone: plain string is rejected';

  throws_ok { str2time('2021-01-15T12:00:00', format => 'ISO8601', timezone => {}) }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_local' method/,
    'timezone: unblessed reference is rejected';

  throws_ok { str2time('2021-01-15T12:00:00', format => 'ISO8601', timezone => bless({}, 'No::Such::Method')) }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_local' method/,
    'timezone: object lacking offset_for_local is rejected';
}

## Resolving a local time (no offset in the string)

{
  my $tz = tz();

  # Winter: CET = UTC+1
  is(str2time('2021-01-15T12:00:00', format => 'ISO8601', timezone => $tz),
     str2time('2021-01-15T11:00:00Z'),
     'local winter time resolves via CET (+1)');

  # Summer: CEST = UTC+2
  is(str2time('2021-07-15T12:00:00', format => 'ISO8601', timezone => $tz),
     str2time('2021-07-15T10:00:00Z'),
     'local summer time resolves via CEST (+2)');

  # Fractional seconds carry through
  is(str2time('2021-01-15T12:00:00.5', format => 'ISO8601', timezone => $tz),
     str2time('2021-01-15T11:00:00Z') + 0.5,
     'fractional local time resolves via the timezone object');
}

## A string offset takes precedence over the timezone object

{
  my $tz = tz();

  is(str2time('2021-01-15T12:00:00+05:00', format => 'ISO8601', timezone => $tz),
     str2time('2021-01-15T07:00:00Z'),
     'numeric offset in the string wins over the timezone object');

  is(str2time('2021-01-15T12:00:00Z', format => 'ISO8601', timezone => $tz),
     str2time('2021-01-15T12:00:00Z'),
     'UTC designator in the string wins over the timezone object');
}

## Gaps and overlaps are resolved by the object's policies

{
  # Spring forward: 02:00 -> 03:00 local on 2021-03-28; [02:00, 03:00) is a gap.
  my $later   = tz(gap_policy => 'later',   overlap_policy => 'earlier');
  my $earlier = tz(gap_policy => 'earlier', overlap_policy => 'later');

  is(str2time('2021-03-28T02:30:00', format => 'ISO8601', timezone => $later),
     str2time('2021-03-28T00:30:00Z'),
     'gap local time, gap_policy later resolves with the post-gap offset (+2)');

  is(str2time('2021-03-28T02:30:00', format => 'ISO8601', timezone => $earlier),
     str2time('2021-03-28T01:30:00Z'),
     'gap local time, gap_policy earlier resolves with the pre-gap offset (+1)');

  # Fall back: 03:00 -> 02:00 local on 2021-10-31; [02:00, 03:00) occurs twice.
  is(str2time('2021-10-31T02:30:00', format => 'ISO8601', timezone => $later),
     str2time('2021-10-31T00:30:00Z'),
     'overlap local time, overlap_policy earlier resolves with the first offset (+2)');

  is(str2time('2021-10-31T02:30:00', format => 'ISO8601', timezone => $earlier),
     str2time('2021-10-31T01:30:00Z'),
     'overlap local time, overlap_policy later resolves with the second offset (+1)');
}

## A leap second is validated against the resolved UTC instant

{
  my $tz = tz();

  # 23:59:60 UTC is 00:59:60 CET. With a CET object, the leap second is
  # written in local time as 00:59:60 on the following day.
  is(str2time('2017-01-01T00:59:60', format => 'ISO8601', timezone => $tz),
     str2time('2016-12-31T23:59:60Z'),
     'leap second in local CET (00:59:60) folds onto the correct UTC instant');

  # A local 23:59:60 does not land on 23:59:60 UTC for a +1 offset.
  throws_ok { str2time('2017-06-30T23:59:60', format => 'ISO8601', timezone => $tz) }
    qr/^Unable to convert: a leap second must occur at 23:59:60 UTC/,
    'local 23:59:60 with a +1 offset is not a valid leap second';
}

## An abbreviated zone in the string cannot be resolved by the object

{
  my $tz = tz();

  throws_ok {
    str2time('Fri, 15 Jan 2021 12:00:00 CET', format => 'RFC2822', timezone => $tz)
  }
    qr/^Unable to convert: cannot resolve abbreviated timezone/,
    'a zone abbreviation in the string is rejected, not resolved via the object';
}

## Without an offset and without a timezone object, conversion still fails

{
  throws_ok { str2time('2021-01-15T12:00:00', format => 'ISO8601') }
    qr/^Unable to convert: timestamp string without a UTC designator or numeric offset/,
    'no offset and no timezone object still fails';
}

done_testing;
