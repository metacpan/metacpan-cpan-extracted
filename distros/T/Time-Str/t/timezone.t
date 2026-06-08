#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str', qw[str2time time2str]);
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

## Partial dates (W3CDTF YYYY and YYYY-MM) resolve via the timezone object.
## The omitted fields default (month/day => 1, time => 00:00:00), and the
## resulting local midnight is converted through the object, so the offset is
## still chosen DST-aware for the implied instant.

{
  my $tz = tz();

  # Year only: 2021 => 2021-01-01T00:00:00 local; CET (+1) in January.
  is(str2time('2021', format => 'W3CDTF', timezone => $tz),
     str2time('2020-12-31T23:00:00Z'),
     'partial date YYYY resolves local midnight via CET (+1)');

  # A bare year is equivalent to its fully defaulted date (W3CDTF requires an
  # offset once a time is present, so the defaulted form is the date YYYY-01-01).
  is(str2time('2021', format => 'W3CDTF', timezone => $tz),
     str2time('2021-01-01', format => 'W3CDTF', timezone => $tz),
     'YYYY equals YYYY-01-01 resolved via the same object');

  # Year-month, winter: 2021-01 => 2021-01-01T00:00:00 local; CET (+1).
  is(str2time('2021-01', format => 'W3CDTF', timezone => $tz),
     str2time('2020-12-31T23:00:00Z'),
     'partial date YYYY-MM (January) resolves local midnight via CET (+1)');

  # Year-month, summer: 2021-07 => 2021-07-01T00:00:00 local; CEST (+2).
  is(str2time('2021-07', format => 'W3CDTF', timezone => $tz),
     str2time('2021-06-30T22:00:00Z'),
     'partial date YYYY-MM (July) resolves local midnight via CEST (+2)');

  # A year-month is equivalent to its fully defaulted date YYYY-MM-01.
  is(str2time('2021-07', format => 'W3CDTF', timezone => $tz),
     str2time('2021-07-01', format => 'W3CDTF', timezone => $tz),
     'YYYY-MM equals YYYY-MM-01 resolved via the same object');
}

## Without a timezone object (and no offset), a partial date still fails

{
  throws_ok { str2time('2021', format => 'W3CDTF') }
    qr/^Unable to convert: timestamp string without a UTC designator or numeric offset/,
    'partial date YYYY without a timezone object or offset still fails';

  throws_ok { str2time('2021-07', format => 'W3CDTF') }
    qr/^Unable to convert: timestamp string without a UTC designator or numeric offset/,
    'partial date YYYY-MM without a timezone object or offset still fails';
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

## ---------------------------------------------------------------------------
## str2time accepts a 'timezone_map' (abbreviation => object) to resolve a zone
## *abbreviation* carried by the string (e.g. an RFC2822 'CET'). The
## abbreviation is the lookup key; the chosen object (which must
## can('offset_for_local')) alone determines the actual, DST-aware offset. A
## bare 'timezone' object is never consulted for an abbreviation -- only the
## map is.
## ---------------------------------------------------------------------------

# US Eastern: UTC-5 (EST) in winter, UTC-4 (EDT) in summer.
my $EST = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');

## Parameter validation: timezone_map must be a HASH reference

{
  my $S = 'Fri, 15 Jan 2021 12:00:00 CET';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => undef) }
    qr/^Parameter 'timezone_map' is not a HASH reference/,
    'timezone_map: undef is rejected';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => 'CET') }
    qr/^Parameter 'timezone_map' is not a HASH reference/,
    'timezone_map: plain string is rejected';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => []) }
    qr/^Parameter 'timezone_map' is not a HASH reference/,
    'timezone_map: array reference is rejected';
}

## Resolving a string's zone abbreviation via the map

{
  my %map = (CET => tz(), EST => $EST);

  # The abbreviation selects the object; CET is +1 in winter.
  is(str2time('Fri, 15 Jan 2021 12:00:00 CET', format => 'RFC2822', timezone_map => \%map),
     str2time('2021-01-15T11:00:00Z'),
     'CET abbreviation resolves via the map (+1)');

  # A different abbreviation in the same map selects a different object.
  is(str2time('Fri, 15 Jan 2021 12:00:00 EST', format => 'RFC2822', timezone_map => \%map),
     str2time('2021-01-15T17:00:00Z'),
     'EST abbreviation resolves via the map (-5)');

  # The object -- not the literal abbreviation -- determines the offset, so it
  # is DST-aware: the same 'CET' label in July resolves to CEST (+2).
  is(str2time('Thu, 15 Jul 2021 12:00:00 CET', format => 'RFC2822', timezone_map => \%map),
     str2time('2021-07-15T10:00:00Z'),
     'the mapped object resolves the offset DST-aware (CET label, CEST offset)');
}

## An abbreviation absent from the map cannot be resolved

{
  throws_ok { str2time('Fri, 15 Jan 2021 12:00:00 CET', format => 'RFC2822', timezone_map => { EST => $EST }) }
    qr/^Unable to convert: cannot resolve abbreviated timezone 'CET'/,
    'an abbreviation missing from the map is rejected';
}

## A bare timezone object is not a fallback for abbreviations -- only the map is

{
  # CET is absent from the map; the timezone object must not be used for it.
  throws_ok { str2time('Fri, 15 Jan 2021 12:00:00 CET', format => 'RFC2822', timezone => tz(), timezone_map => { EST => $EST }) }
    qr/^Unable to convert: cannot resolve abbreviated timezone 'CET'/,
    'a timezone object does not resolve an abbreviation absent from the map';

  # When the abbreviation IS in the map, the mapped object wins over 'timezone'.
  is(str2time('Fri, 15 Jan 2021 12:00:00 CET', format => 'RFC2822', timezone => $EST, timezone_map => { CET => tz() }),
     str2time('2021-01-15T11:00:00Z'),
     'the mapped object takes precedence over a bare timezone object');
}

## A map entry for the matched abbreviation must be a valid timezone object

{
  my $S = 'Fri, 15 Jan 2021 12:00:00 CET';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => { CET => undef }) }
    qr/^timezone_map value for 'CET' is not an object with an 'offset_for_local' method/,
    'map value: undef is rejected';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => { CET => 'CET' }) }
    qr/^timezone_map value for 'CET' is not an object with an 'offset_for_local' method/,
    'map value: plain string is rejected';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => { CET => {} }) }
    qr/^timezone_map value for 'CET' is not an object with an 'offset_for_local' method/,
    'map value: unblessed reference is rejected';

  throws_ok { str2time($S, format => 'RFC2822', timezone_map => { CET => bless({}, 'No::Such::Method') }) }
    qr/^timezone_map value for 'CET' is not an object with an 'offset_for_local' method/,
    'map value: object lacking offset_for_local is rejected';
}

## A timezone_map is irrelevant when the string carries no abbreviation

{
  # An ISO8601 local time has no abbreviation, so the map is never consulted
  # and conversion still fails for want of an offset.
  throws_ok { str2time('2021-01-15T12:00:00', format => 'ISO8601', timezone_map => { CET => tz() }) }
    qr/^Unable to convert: timestamp string without a UTC designator or numeric offset/,
    'timezone_map alone does not resolve a string without an abbreviation';
}

## ---------------------------------------------------------------------------
## time2str accepts a 'timezone' object (anything that can('offset_for_utc'))
## to render a UTC epoch as local wall-clock time. The object is consulted at
## the given instant, so the rendered offset tracks DST automatically. It is
## mutually exclusive with the numeric 'offset' parameter.
## ---------------------------------------------------------------------------

## Parameter validation

{
  my $t = str2time('2021-01-15T11:00:00Z');

  throws_ok { time2str($t, timezone => undef) }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_utc' method/,
    'time2str timezone: undef is rejected';

  throws_ok { time2str($t, timezone => 'CET') }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_utc' method/,
    'time2str timezone: plain string is rejected';

  throws_ok { time2str($t, timezone => {}) }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_utc' method/,
    'time2str timezone: unblessed reference is rejected';

  throws_ok { time2str($t, timezone => bless({}, 'No::Such::Method')) }
    qr/^Parameter 'timezone' is not an object with an 'offset_for_utc' method/,
    'time2str timezone: object lacking offset_for_utc is rejected';
}

## 'timezone' and 'offset' are mutually exclusive (either order)

{
  my $tz = tz();
  my $t  = str2time('2021-01-15T11:00:00Z');

  throws_ok { time2str($t, timezone => $tz, offset => 60) }
    qr/^Parameter 'offset' is mutually exclusive with 'timezone'/,
    'time2str: timezone followed by offset is rejected';

  throws_ok { time2str($t, offset => 60, timezone => $tz) }
    qr/^Parameter 'timezone' is mutually exclusive with 'offset'/,
    'time2str: offset followed by timezone is rejected';
}

## Rendering a UTC epoch as local wall-clock time

{
  my $tz = tz();

  # Winter: CET = UTC+1
  is(time2str(str2time('2021-01-15T11:00:00Z'), format => 'ISO8601', timezone => $tz),
     '2021-01-15T12:00:00+01:00',
     'winter UTC instant renders as CET (+01:00)');

  # Summer: CEST = UTC+2
  is(time2str(str2time('2021-07-15T10:00:00Z'), format => 'ISO8601', timezone => $tz),
     '2021-07-15T12:00:00+02:00',
     'summer UTC instant renders as CEST (+02:00)');

  # The default (RFC3339) format honours the timezone object too.
  is(time2str(str2time('2021-07-15T10:00:00Z'), timezone => $tz),
     '2021-07-15T12:00:00+02:00',
     'default RFC3339 format renders via the timezone object');

  # Fractional seconds carry through.
  is(time2str(str2time('2021-07-15T10:00:00Z') + 0.5, precision => 3, timezone => $tz),
     '2021-07-15T12:00:00.500+02:00',
     'fractional second renders via the timezone object');
}

## The offset is resolved at the given instant, across DST transitions

{
  my $tz = tz();

  # Spring forward: local 02:00 -> 03:00 on 2021-03-28, i.e. at 01:00:00Z.
  my $spring = str2time('2021-03-28T01:00:00Z');
  is(time2str($spring - 1, format => 'ISO8601', timezone => $tz),
     '2021-03-28T01:59:59+01:00',
     'one second before spring-forward renders with the pre-transition offset (+1)');
  is(time2str($spring, format => 'ISO8601', timezone => $tz),
     '2021-03-28T03:00:00+02:00',
     'at spring-forward the local clock jumps to 03:00 with the post-transition offset (+2)');

  # Fall back: local 03:00 -> 02:00 on 2021-10-31, i.e. at 01:00:00Z.
  my $fall = str2time('2021-10-31T01:00:00Z');
  is(time2str($fall - 1, format => 'ISO8601', timezone => $tz),
     '2021-10-31T02:59:59+02:00',
     'one second before fall-back renders with the pre-transition offset (+2)');
  is(time2str($fall, format => 'ISO8601', timezone => $tz),
     '2021-10-31T02:00:00+01:00',
     'at fall-back the local clock repeats 02:00 with the post-transition offset (+1)');
}

## time2str via 'timezone' round-trips through str2time

{
  my $tz = tz();
  for my $iso ('2021-01-15T11:00:00Z', '2021-07-15T10:00:00Z') {
    my $t   = str2time($iso);
    my $str = time2str($t, format => 'ISO8601', timezone => $tz);
    is(str2time($str, format => 'ISO8601'), $t,
      "time2str(timezone) output round-trips through str2time ($iso)");
  }
}

done_testing;
