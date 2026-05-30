#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[ throws_ok ];

use Time::Str::Time qw[ timegm_modern ];

use_ok('Time::TZif');
use_ok('Time::TZif::POSIX');

## Constructor

throws_ok { Time::TZif::POSIX->new() }
  qr/Usage:/,
  'new: no arguments';

throws_ok { Time::TZif::POSIX->new(bogus => 1) }
  qr/Unrecognised named parameter: 'bogus'/,
  'new: unknown parameter';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0', bogus => 1) }
  qr/Unrecognised named parameter: 'bogus'/,
  'new: tz_string with unknown parameter';

throws_ok { Time::TZif::POSIX->new(gap_policy => 'later') }
  qr/Parameter 'tz_string' is required/,
  'new: missing tz_string';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0', gap_policy => 'invalid') }
  qr/Invalid policy value for the parameter 'gap_policy'/,
  'new: invalid gap_policy';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0', overlap_policy => 'invalid') }
  qr/Invalid policy value for the parameter 'overlap_policy'/,
  'new: invalid overlap_policy';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0', name => '123') }
  qr/Invalid value for the parameter 'name'/,
  'new: invalid name (starts with digit)';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0', name => '') }
  qr/Invalid value for the parameter 'name'/,
  'new: invalid name (empty string)';

## Constructor defaults

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  is($tz->tz_string,      'EST5EDT,M3.2.0,M11.1.0', 'tz_string accessor');
  is($tz->gap_policy,     'reject', 'default gap_policy is reject');
  is($tz->overlap_policy, 'reject', 'default overlap_policy is reject');
}

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'EST5EDT,M3.2.0,M11.1.0',
    gap_policy     => 'later',
    overlap_policy => 'std',
  );
  is($tz->gap_policy,     'later', 'custom gap_policy preserved');
  is($tz->overlap_policy, 'std',   'custom overlap_policy preserved');
}

## name / has_name

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  is($tz->name, undef, 'name is undef when not provided');
  ok(!$tz->has_name, 'has_name is false when not provided');
}

{
  my $tz = Time::TZif::POSIX->new(
    tz_string => 'EST5EDT,M3.2.0,M11.1.0',
    name      => 'America/New_York',
  );
  is($tz->name, 'America/New_York', 'name accessor returns provided name');
  ok($tz->has_name, 'has_name is true when name provided');
}

## with_name

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0')->with_name() }
  qr/^Usage: /,
  'with_name: no arguments';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0')->with_name('123') }
  qr/Invalid name value/,
  'with_name: invalid name';

{
  my $tz1 = Time::TZif::POSIX->new(
    tz_string => 'EST5EDT,M3.2.0,M11.1.0',
    name      => 'America/New_York',
  );
  my $tz2 = $tz1->with_name('US/Eastern');
  isnt($tz2, $tz1, 'with_name: returns new object when name differs');
  is($tz2->name, 'US/Eastern', 'with_name: new object has updated name');
  is($tz2->tz_string, $tz1->tz_string, 'with_name: shares tz_string');
  is($tz2->gap_policy, $tz1->gap_policy, 'with_name: shares gap_policy');
}

{
  my $tz1 = Time::TZif::POSIX->new(
    tz_string => 'EST5EDT,M3.2.0,M11.1.0',
    name      => 'America/New_York',
  );
  my $tz2 = $tz1->with_name('America/New_York');
  is($tz2, $tz1, 'with_name: returns same object when name unchanged');
}

{
  my $tz1 = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  my $tz2 = $tz1->with_name('America/New_York');
  isnt($tz2, $tz1, 'with_name: returns new object when name was undef');
  is($tz2->name, 'America/New_York', 'with_name: sets name from undef');
}

## with_gap_policy

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0')->with_gap_policy() }
  qr/^Usage: /,
  'with_gap_policy: no arguments';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0')->with_gap_policy('invalid') }
  qr/Invalid policy value/,
  'with_gap_policy: invalid policy';

{
  my $tz1 = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  my $tz2 = $tz1->with_gap_policy('later');
  isnt($tz2, $tz1, 'with_gap_policy: returns new object when policy differs');
  is($tz2->gap_policy, 'later', 'with_gap_policy: new object has updated policy');
  is($tz2->overlap_policy, $tz1->overlap_policy, 'with_gap_policy: overlap_policy unchanged');
}

{
  my $tz1 = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  my $tz2 = $tz1->with_gap_policy('reject');
  is($tz2, $tz1, 'with_gap_policy: returns same object when policy unchanged');
}

## with_overlap_policy

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0')->with_overlap_policy() }
  qr/^Usage: /,
  'with_overlap_policy: no arguments';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0')->with_overlap_policy('invalid') }
  qr/Invalid policy value/,
  'with_overlap_policy: invalid policy';

{
  my $tz1 = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  my $tz2 = $tz1->with_overlap_policy('earlier');
  isnt($tz2, $tz1, 'with_overlap_policy: returns new object when policy differs');
  is($tz2->overlap_policy, 'earlier', 'with_overlap_policy: new object has updated policy');
  is($tz2->gap_policy, $tz1->gap_policy, 'with_overlap_policy: gap_policy unchanged');
}

{
  my $tz1 = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');
  my $tz2 = $tz1->with_overlap_policy('reject');
  is($tz2, $tz1, 'with_overlap_policy: returns same object when policy unchanged');
}

## Parsing: invalid TZ strings

throws_ok { Time::TZif::POSIX->new(tz_string => '') }
  qr/Unable to parse POSIX TZ string/,
  'parse: empty string';

throws_ok { Time::TZif::POSIX->new(tz_string => 'X5') }
  qr/Unable to parse POSIX TZ string/,
  'parse: name too short (less than 3 chars)';

throws_ok { Time::TZif::POSIX->new(tz_string => '<AB>5') }
  qr/Unable to parse POSIX TZ string/,
  'parse: quoted name too short (less than 3 chars)';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT') }
  qr/Unable to parse POSIX TZ string/,
  'parse: DST name without rules';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0') }
  qr/Unable to parse POSIX TZ string/,
  'parse: only one rule';

## Parsing: offset validation

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST25') }
  qr/offset time is out of range/,
  'parse: offset hours > 24';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5:60') }
  qr/offset time is out of range/,
  'parse: offset minutes > 59';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5:00:60') }
  qr/offset time is out of range/,
  'parse: offset seconds > 59';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT25,M3.2.0,M11.1.0') }
  qr/offset time is out of range/,
  'parse: DST offset hours > 24';

## Parsing: rule validation

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M0.2.0,M11.1.0') }
  qr/rule month out of range/,
  'parse: rule month 0';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M13.2.0,M11.1.0') }
  qr/rule month out of range/,
  'parse: rule month 13';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,J0,M11.1.0') }
  qr/Julian day out of range/,
  'parse: Julian day 0';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,J366,M11.1.0') }
  qr/Julian day out of range/,
  'parse: Julian day 366';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,366,M11.1.0') }
  qr/zero-based day out of range/,
  'parse: zero-based day 366';

## Parsing: rule time validation

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0/168,M11.1.0') }
  qr/rule time is out of range/,
  'parse: rule time hours > 167';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0/2:60,M11.1.0') }
  qr/rule time is out of range/,
  'parse: rule time minutes > 59';

throws_ok { Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0/2:00:60,M11.1.0') }
  qr/rule time is out of range/,
  'parse: rule time seconds > 59';

## Parsing: valid TZ strings

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5');
  my @info = $tz->type_info_for_utc(0);
  is($info[0], -18000, 'fixed offset: EST5 offset');
  is($info[1], 0,      'fixed offset: EST5 is_dst');
  is($info[2], 'EST',  'fixed offset: EST5 abbreviation');
}

{
  my $tz = Time::TZif::POSIX->new(tz_string => '<+05>-5');
  my @info = $tz->type_info_for_utc(0);
  is($info[0], 18000,  'quoted name: <+05>-5 offset');
  is($info[1], 0,      'quoted name: <+05>-5 is_dst');
  is($info[2], '+05',  'quoted name: <+05>-5 abbreviation');
}

{
  my $tz = Time::TZif::POSIX->new(tz_string => '<-03>3');
  my @info = $tz->type_info_for_utc(0);
  is($info[0], -10800, 'quoted name: <-03>3 offset');
  is($info[2], '-03',  'quoted name: <-03>3 abbreviation');
}

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5:30');
  is($tz->offset_for_utc(0), -19800, 'offset with minutes: EST5:30');
}

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5:30:15');
  is($tz->offset_for_utc(0), -19815, 'offset with minutes and seconds: EST5:30:15');
}

## Parsing: DST offset defaults to std + 1 hour when omitted

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'EST5EDT,M3.2.0,M11.1.0',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $summer = timegm_modern(0, 0, 12, 15, 7, 2024);
  is($tz->offset_for_utc($summer), -14400,
    'DST offset defaults to std + 1h when omitted');
}

## Parsing: explicit DST offset

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'EST5EDT4,M3.2.0,M11.1.0',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $summer = timegm_modern(0, 0, 12, 15, 7, 2024);
  is($tz->offset_for_utc($summer), -14400,
    'explicit DST offset: EDT4 = -14400');
}

## Fixed offset (no DST)

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'UTC0');
  is($tz->offset_for_utc(0),           0, 'UTC0: offset at epoch');
  is($tz->offset_for_utc(1e9),         0, 'UTC0: offset at 1e9');
  is($tz->offset_for_local(0),         0, 'UTC0: local offset at epoch');
  is($tz->offset_for_local(1e9),       0, 'UTC0: local offset at 1e9');

  my @info = $tz->type_info_for_utc(0);
  is($info[0], 0,     'UTC0: type_info offset');
  is($info[1], 0,     'UTC0: type_info is_dst');
  is($info[2], 'UTC', 'UTC0: type_info abbreviation');

  @info = $tz->type_info_for_local(0);
  is($info[0], 0,     'UTC0: type_info_for_local offset');
  is($info[1], 0,     'UTC0: type_info_for_local is_dst');
  is($info[2], 'UTC', 'UTC0: type_info_for_local abbreviation');
}

## US Eastern (EST/EDT) — Mm.w.d rules

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0/2,M11.1.0/2');
  my $EST = -18000;
  my $EDT = -14400;

  # Winter: 2024-01-15 12:00:00 UTC
  {
    my $utc = timegm_modern(0, 0, 12, 15, 1, 2024);
    is($tz->offset_for_utc($utc), $EST, 'US Eastern: winter EST');
    my @info = $tz->type_info_for_utc($utc);
    is($info[0], $EST, 'US Eastern: winter type_info offset');
    is($info[1], 0,    'US Eastern: winter type_info is_dst');
    is($info[2], 'EST', 'US Eastern: winter type_info abbreviation');
  }

  # Summer: 2024-07-15 12:00:00 UTC
  {
    my $utc = timegm_modern(0, 0, 12, 15, 7, 2024);
    is($tz->offset_for_utc($utc), $EDT, 'US Eastern: summer EDT');
    my @info = $tz->type_info_for_utc($utc);
    is($info[0], $EDT, 'US Eastern: summer type_info offset');
    is($info[1], 1,    'US Eastern: summer type_info is_dst');
    is($info[2], 'EDT', 'US Eastern: summer type_info abbreviation');
  }

  # Spring forward 2024: 2024-03-10 07:00:00 UTC (2nd Sun of March)
  {
    my $spring = timegm_modern(0, 0, 7, 10, 3, 2024);
    is($tz->offset_for_utc($spring - 1), $EST, 'US Eastern: 1s before spring = EST');
    is($tz->offset_for_utc($spring),     $EDT, 'US Eastern: at spring = EDT');
  }

  # Fall back 2024: 2024-11-03 06:00:00 UTC (1st Sun of November)
  {
    my $fall = timegm_modern(0, 0, 6, 3, 11, 2024);
    is($tz->offset_for_utc($fall - 1), $EDT, 'US Eastern: 1s before fall = EDT');
    is($tz->offset_for_utc($fall),     $EST, 'US Eastern: at fall = EST');
  }

  # Gap: 2024-03-10 02:30 local (non-existing)
  {
    my $in_gap = timegm_modern(0, 30, 2, 10, 3, 2024);

    throws_ok { $tz->offset_for_local($in_gap) }
      qr/Unable to resolve local time: non-existing time \(gap\)/,
      'US Eastern: gap default (reject)';

    is($tz->offset_for_local($in_gap, gap_policy => 'earlier'), $EST,
      'US Eastern: gap earlier = EST');
    is($tz->offset_for_local($in_gap, gap_policy => 'later'), $EDT,
      'US Eastern: gap later = EDT');
    is($tz->offset_for_local($in_gap, gap_policy => 'std'), $EST,
      'US Eastern: gap std = EST');
    is($tz->offset_for_local($in_gap, gap_policy => 'dst'), $EDT,
      'US Eastern: gap dst = EDT');
  }

  # Overlap: 2024-11-03 01:30 local (ambiguous)
  {
    my $in_overlap = timegm_modern(0, 30, 1, 3, 11, 2024);

    throws_ok { $tz->offset_for_local($in_overlap) }
      qr/Unable to resolve local time: ambiguous time \(overlap\)/,
      'US Eastern: overlap default (reject)';

    is($tz->offset_for_local($in_overlap, overlap_policy => 'earlier'), $EDT,
      'US Eastern: overlap earlier = EDT');
    is($tz->offset_for_local($in_overlap, overlap_policy => 'later'), $EST,
      'US Eastern: overlap later = EST');
    is($tz->offset_for_local($in_overlap, overlap_policy => 'std'), $EST,
      'US Eastern: overlap std = EST');
    is($tz->offset_for_local($in_overlap, overlap_policy => 'dst'), $EDT,
      'US Eastern: overlap dst = EDT');
  }

  # type_info_for_local
  {
    my $winter = timegm_modern(0, 0, 12, 15, 1, 2024);
    my @info = $tz->type_info_for_local($winter);
    is($info[0], $EST, 'US Eastern: type_info_for_local winter offset');
    is($info[1], 0,    'US Eastern: type_info_for_local winter is_dst');
    is($info[2], 'EST', 'US Eastern: type_info_for_local winter abbreviation');
  }
  {
    my $summer = timegm_modern(0, 0, 12, 15, 7, 2024);
    my @info = $tz->type_info_for_local($summer);
    is($info[0], $EDT, 'US Eastern: type_info_for_local summer offset');
    is($info[1], 1,    'US Eastern: type_info_for_local summer is_dst');
    is($info[2], 'EDT', 'US Eastern: type_info_for_local summer abbreviation');
  }

  # Gap boundaries
  {
    my $gap_start = timegm_modern(0, 0, 2, 10, 3, 2024);
    throws_ok { $tz->offset_for_local($gap_start) }
      qr/non-existing time \(gap\)/,
      'US Eastern: exactly at gap start (02:00) = gap';
  }
  {
    my $gap_end = timegm_modern(0, 0, 3, 10, 3, 2024);
    is($tz->offset_for_local($gap_end), $EDT,
      'US Eastern: exactly at gap end (03:00) = EDT');
  }

  # Overlap boundaries
  {
    my $overlap_start = timegm_modern(0, 0, 1, 3, 11, 2024);
    is($tz->offset_for_local($overlap_start, overlap_policy => 'earlier'), $EDT,
      'US Eastern: overlap start (01:00) earlier = EDT');
    is($tz->offset_for_local($overlap_start, overlap_policy => 'later'), $EST,
      'US Eastern: overlap start (01:00) later = EST');
  }
  {
    my $overlap_end = timegm_modern(0, 0, 2, 3, 11, 2024);
    is($tz->offset_for_local($overlap_end), $EST,
      'US Eastern: overlap end (02:00) = EST (unambiguous)');
  }

  # Constructor defaults + per-call overrides
  {
    my $tz_custom = Time::TZif::POSIX->new(
      tz_string      => 'EST5EDT,M3.2.0/2,M11.1.0/2',
      gap_policy     => 'later',
      overlap_policy => 'earlier',
    );

    my $in_gap = timegm_modern(0, 30, 2, 10, 3, 2024);
    is($tz_custom->offset_for_local($in_gap), $EDT,
      'constructor gap_policy=later: gap returns EDT');

    my $in_overlap = timegm_modern(0, 30, 1, 3, 11, 2024);
    is($tz_custom->offset_for_local($in_overlap), $EDT,
      'constructor overlap_policy=earlier: overlap returns EDT');

    is($tz_custom->offset_for_local($in_gap, gap_policy => 'earlier'), $EST,
      'per-call gap_policy overrides constructor');
    is($tz_custom->offset_for_local($in_overlap, overlap_policy => 'later'), $EST,
      'per-call overlap_policy overrides constructor');
  }
}

## CET/CEST (Central European Time)

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'CET-1CEST,M3.5.0/2,M10.5.0/3',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $CET  = 3600;
  my $CEST = 7200;

  # Winter
  {
    my $utc = timegm_modern(0, 0, 12, 15, 1, 2024);
    is($tz->offset_for_utc($utc), $CET, 'CET: winter');
    my @info = $tz->type_info_for_utc($utc);
    is($info[2], 'CET', 'CET: winter abbreviation');
  }

  # Summer
  {
    my $utc = timegm_modern(0, 0, 12, 15, 7, 2024);
    is($tz->offset_for_utc($utc), $CEST, 'CEST: summer');
    my @info = $tz->type_info_for_utc($utc);
    is($info[2], 'CEST', 'CEST: summer abbreviation');
  }

  # Spring: last Sun of March 2024 = Mar 31, 02:00 CET -> 01:00 UTC
  {
    my $spring = timegm_modern(0, 0, 1, 31, 3, 2024);
    is($tz->offset_for_utc($spring - 1), $CET,  'CET: 1s before spring = CET');
    is($tz->offset_for_utc($spring),     $CEST, 'CET: at spring = CEST');
  }

  # Fall: last Sun of October 2024 = Oct 27, 03:00 CEST -> 01:00 UTC
  {
    my $fall = timegm_modern(0, 0, 1, 27, 10, 2024);
    is($tz->offset_for_utc($fall - 1), $CEST, 'CET: 1s before fall = CEST');
    is($tz->offset_for_utc($fall),     $CET,  'CET: at fall = CET');
  }
}

## Southern hemisphere: NZST/NZDT (New Zealand)

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'NZST-12NZDT,M9.5.0,M4.1.0/3',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $NZST = 43200;   # UTC+12
  my $NZDT = 46800;   # UTC+13

  # January (NZ summer) -> NZDT
  {
    my $utc = timegm_modern(0, 0, 0, 15, 1, 2024);
    is($tz->offset_for_utc($utc), $NZDT, 'NZ: January = NZDT');
    my @info = $tz->type_info_for_utc($utc);
    is($info[2], 'NZDT', 'NZ: January abbreviation');
  }

  # July (NZ winter) -> NZST
  {
    my $utc = timegm_modern(0, 0, 0, 15, 7, 2024);
    is($tz->offset_for_utc($utc), $NZST, 'NZ: July = NZST');
    my @info = $tz->type_info_for_utc($utc);
    is($info[2], 'NZST', 'NZ: July abbreviation');
  }

  # December (NZ summer again) -> NZDT
  {
    my $utc = timegm_modern(0, 0, 0, 15, 12, 2024);
    is($tz->offset_for_utc($utc), $NZDT, 'NZ: December = NZDT');
  }
}

## Multiple years

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'EST5EDT,M3.2.0/2,M11.1.0/2',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $EST = -18000;
  my $EDT = -14400;

  # 2020: spring forward Mar 8, fall back Nov 1
  {
    my $winter = timegm_modern(0, 0, 12, 1, 1, 2020);
    is($tz->offset_for_utc($winter), $EST, '2020: January = EST');

    my $summer = timegm_modern(0, 0, 12, 1, 6, 2020);
    is($tz->offset_for_utc($summer), $EDT, '2020: June = EDT');
  }

  # 2030
  {
    my $winter = timegm_modern(0, 0, 12, 1, 1, 2030);
    is($tz->offset_for_utc($winter), $EST, '2030: January = EST');

    my $summer = timegm_modern(0, 0, 12, 1, 6, 2030);
    is($tz->offset_for_utc($summer), $EDT, '2030: June = EDT');
  }
}

## Cross-validation with Time::TZif (file-based)

SKIP: {
  my $tzdir;
  eval { 
    require Time::Str::Util;
    $tzdir = Time::Str::Util::find_tzdb_directory();
  };

  skip "zoneinfo directory not available", 1
    unless defined $tzdir && -f "$tzdir/America/New_York";

  my $tzif = Time::TZif->new(
    path           => "$tzdir/America/New_York",
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $posix = Time::TZif::POSIX->new(
    tz_string      => 'EST5EDT,M3.2.0,M11.1.0',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );

  my $mismatches = 0;
  for my $month (1..12) {
    for my $day (1..28) {
      for my $hour (0, 6, 12, 18) {
        my $epoch = timegm_modern(0, 0, $hour, $day, $month, 2024);
        $mismatches++ if $tzif->offset_for_utc($epoch) != $posix->offset_for_utc($epoch);
      }
    }
  }
  is($mismatches, 0, 'cross-validation: TZif vs POSIX for 2024 (UTC)');

  $mismatches = 0;
  for my $month (1..12) {
    for my $day (1..28) {
      for my $hour (0, 6, 12, 18) {
        my $local = timegm_modern(0, 0, $hour, $day, $month, 2024);
        $mismatches++ if $tzif->offset_for_local($local) != $posix->offset_for_local($local);
      }
    }
  }
  is($mismatches, 0, 'cross-validation: TZif vs POSIX for 2024 (local)');
}

## Parameter validation on methods

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'EST5EDT,M3.2.0,M11.1.0');

  throws_ok { $tz->offset_for_utc() }
    qr/Usage:/,
    'offset_for_utc: no args';

  throws_ok { $tz->type_info_for_utc() }
    qr/Usage:/,
    'type_info_for_utc: no args';

  throws_ok { $tz->offset_for_local(0, overlap_policy => 'invalid') }
    qr/Invalid policy value for the parameter 'overlap_policy'/,
    'offset_for_local: invalid overlap_policy';

  throws_ok { $tz->offset_for_local(0, gap_policy => 'invalid') }
    qr/Invalid policy value for the parameter 'gap_policy'/,
    'offset_for_local: invalid gap_policy';

  throws_ok { $tz->offset_for_local(0, bogus => 1) }
    qr/Unrecognised named parameter: 'bogus'/,
    'offset_for_local: unknown parameter';

  throws_ok { $tz->type_info_for_local(0, bogus => 1) }
    qr/Unrecognised named parameter: 'bogus'/,
    'type_info_for_local: unknown parameter';
}

## Edge cases: Jn rule form

{
  # J60 = March 1 (never counts Feb 29)
  # Use a simple test: fixed transition using Julian days
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'STD5DST,J60/2,J300/2',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );

  # 2024 is a leap year: J60 = day 61 (Mar 1), J300 = day 301 (Oct 27)
  # Non-leap 2023: J60 = day 60 (Mar 1), J300 = day 300 (Oct 27)

  my $winter_2024 = timegm_modern(0, 0, 12, 15, 1, 2024);
  is($tz->offset_for_utc($winter_2024), -18000, 'Jn: winter 2024 = STD');

  my $summer_2024 = timegm_modern(0, 0, 12, 15, 6, 2024);
  is($tz->offset_for_utc($summer_2024), -14400, 'Jn: summer 2024 = DST');

  my $winter_2023 = timegm_modern(0, 0, 12, 15, 1, 2023);
  is($tz->offset_for_utc($winter_2023), -18000, 'Jn: winter 2023 = STD');

  my $summer_2023 = timegm_modern(0, 0, 12, 15, 6, 2023);
  is($tz->offset_for_utc($summer_2023), -14400, 'Jn: summer 2023 = DST');
}

## Edge cases: n rule form (zero-based, counts Feb 29)

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'STD5DST,59/2,299/2',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );

  # 2024 leap year: day 59 = Feb 29, day 299 = Oct 25
  # 2023 non-leap:  day 59 = Mar 1, day 299 = Oct 27

  my $winter_2024 = timegm_modern(0, 0, 12, 15, 1, 2024);
  is($tz->offset_for_utc($winter_2024), -18000, 'n rule: winter 2024 = STD');

  my $summer_2024 = timegm_modern(0, 0, 12, 15, 6, 2024);
  is($tz->offset_for_utc($summer_2024), -14400, 'n rule: summer 2024 = DST');
}

## Edge case: w=5 (last occurrence of weekday)

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'CET-1CEST,M3.5.0/2,M10.5.0/3',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );

  # 2024: last Sun of March = Mar 31
  my $before = timegm_modern(0, 59, 0, 31, 3, 2024);
  is($tz->offset_for_utc($before), 3600, 'w=5: before last-Sun-of-March = CET');

  my $after = timegm_modern(0, 0, 1, 31, 3, 2024);
  is($tz->offset_for_utc($after), 7200, 'w=5: at last-Sun-of-March 01:00 UTC = CEST');

  # 2025: last Sun of March = Mar 30
  my $before_2025 = timegm_modern(0, 59, 0, 30, 3, 2025);
  is($tz->offset_for_utc($before_2025), 3600, 'w=5: 2025 before last-Sun-of-March = CET');

  my $after_2025 = timegm_modern(0, 0, 1, 30, 3, 2025);
  is($tz->offset_for_utc($after_2025), 7200, 'w=5: 2025 at last-Sun-of-March 01:00 UTC = CEST');
}

## Edge case: rule with non-default transition time

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'CET-1CEST,M3.5.0/2,M10.5.0/3',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );

  # Fall back: last Sun Oct 2024 = Oct 27, 03:00 CEST (01:00 UTC)
  my $fall = timegm_modern(0, 0, 1, 27, 10, 2024);
  is($tz->offset_for_utc($fall - 1), 7200, 'non-default time: 1s before fall = CEST');
  is($tz->offset_for_utc($fall),     3600, 'non-default time: at fall = CET');
}

## Edge case: negative offset

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'IST-5:30');
  is($tz->offset_for_utc(0), 19800, 'negative offset: IST-5:30 = +19800');
}

## Edge case: maximum offset (24 hours)

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'MAX24');
  is($tz->offset_for_utc(0), -86400, 'max offset: 24h = -86400');
}

{
  my $tz = Time::TZif::POSIX->new(tz_string => 'MAX-24');
  is($tz->offset_for_utc(0), 86400, 'max negative offset: -24h = 86400');
}

## Cross-year transitions

{
  # Negative rule time pushes DST start transition into previous year.
  # STD3DST,M1.1.1/-1,M6.1.1/2
  # DST starts: 1st Monday of January at -01:00 wall (STD offset = -10800)
  # For 2024: 1st Mon Jan = Jan 1 (Mon). Wall = midnight + (-3600) = 23:00 prev day
  # UTC = midnight Jan 1 + (-3600) - (-10800) = midnight Jan 1 + 7200 = Jan 1 02:00 UTC
  # Actually with -1h rule time: midnight + (-3600) wall, minus offset (-10800):
  # epoch = midnight_Jan1 + (-3600) - (-10800) = midnight_Jan1 + 7200
  # So t_start = Jan 1 02:00 UTC — still in the same year.
  #
  # More extreme: rule time = -25, offset = -43200 (UTC-12)
  # STD12DST,M1.1.1/-25,M6.1.1/2
  # UTC = midnight_Jan1 + (-25*3600) - (-43200) = midnight_Jan1 - 90000 + 43200
  #     = midnight_Jan1 - 46800 = Dec 31 prev year ~11:00 UTC
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'STD12DST,M1.1.1/-25,M6.1.1/2',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $STD = -43200;
  my $DST = -39600;

  # Mid-year should be STD (DST ended in June)
  my $july = timegm_modern(0, 0, 12, 15, 7, 2024);
  is($tz->offset_for_utc($july), $STD, 'cross-year: July = STD');

  # February should be DST (DST started around Jan 1)
  my $feb = timegm_modern(0, 0, 12, 15, 2, 2024);
  is($tz->offset_for_utc($feb), $DST, 'cross-year: February = DST');

  # The critical test: late December 2023, just before the cross-year transition
  # The DST start for 2024 has a UTC epoch in late December 2023
  # 2024 Jan 1 is a Monday (1st Mon of Jan)
  # UTC = midnight_Jan1_2024 + (-25*3600) - (-43200) = 1704067200 - 90000 + 43200
  #     = 1704067200 - 46800 = 1704020400 = Dec 31 2023 11:00 UTC
  my $before_cross = timegm_modern(0, 0, 10, 31, 12, 2023);  # Dec 31 10:00 UTC
  is($tz->offset_for_utc($before_cross), $STD,
    'cross-year: Dec 31 10:00 UTC before cross-year transition = STD');

  my $after_cross = timegm_modern(0, 0, 12, 31, 12, 2023);  # Dec 31 12:00 UTC
  is($tz->offset_for_utc($after_cross), $DST,
    'cross-year: Dec 31 12:00 UTC after cross-year transition = DST');
}

{
  # Late-December rule with large positive time pushing into next year.
  # STD12DST,M6.1.1/2,M12.5.1/49
  # DST ends: last Monday of December at 49:00 wall (DST offset = -39600)
  # For 2024: last Mon Dec = Dec 30.
  # UTC = midnight_Dec30 + 49*3600 - (-39600) = midnight_Dec30 + 176400 + 39600
  #     = midnight_Dec30 + 216000 = midnight_Dec30 + 60h = Jan 1 2025 12:00 UTC
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'STD12DST,M6.1.1/2,M12.5.1/49',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $STD = -43200;
  my $DST = -39600;

  # August = DST (between June start and December end)
  my $aug = timegm_modern(0, 0, 12, 15, 8, 2024);
  is($tz->offset_for_utc($aug), $DST, 'cross-year forward: August = DST');

  # March = STD
  my $mar = timegm_modern(0, 0, 12, 15, 3, 2024);
  is($tz->offset_for_utc($mar), $STD, 'cross-year forward: March = STD');

  # Jan 1 2025 just before the cross-year DST end (still DST)
  my $before_end = timegm_modern(0, 0, 11, 1, 1, 2025);
  is($tz->offset_for_utc($before_end), $DST,
    'cross-year forward: Jan 1 11:00 UTC before DST end = DST');

  # Jan 1 2025 after the cross-year DST end (now STD)
  my $after_end = timegm_modern(0, 0, 13, 1, 1, 2025);
  is($tz->offset_for_utc($after_end), $STD,
    'cross-year forward: Jan 1 13:00 UTC after DST end = STD');
}

## Cross-year: n-rule differs between leap and non-leap years
#
# n=364 (day 365) resolves to Dec 30 in leap years but Dec 31 in
# non-leap years. With a 26h rule time, the non-leap year transition
# crosses into the next year while the leap year transition does not.

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'STD5DST,59/2,364/26',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $STD = -18000;
  my $DST = -14400;

  # 2024 (leap): day 365 = Dec 30, transition at Dec 31 06:00 UTC (within year)
  {
    my $before = timegm_modern(0, 0, 5, 31, 12, 2024);
    is($tz->offset_for_utc($before), $DST,
      'n-rule leap: Dec 31 2024 05:00 UTC = DST');

    my $after = timegm_modern(0, 0, 7, 31, 12, 2024);
    is($tz->offset_for_utc($after), $STD,
      'n-rule leap: Dec 31 2024 07:00 UTC = STD');
  }

  # 2025 (non-leap): day 365 = Dec 31, transition at Jan 1 2026 06:00 UTC (crosses year)
  {
    my $before = timegm_modern(0, 0, 5, 1, 1, 2026);
    is($tz->offset_for_utc($before), $DST,
      'n-rule non-leap: Jan 1 2026 05:00 UTC = DST (before cross-year transition)');

    my $after = timegm_modern(0, 0, 7, 1, 1, 2026);
    is($tz->offset_for_utc($after), $STD,
      'n-rule non-leap: Jan 1 2026 07:00 UTC = STD (after cross-year transition)');
  }

  # Local: overlap at cross-year DST end (01:00-02:00 local Jan 1 2026)
  {
    my $local_before = timegm_modern(0, 30, 0, 1, 1, 2026);
    is($tz->offset_for_local($local_before), $DST,
      'n-rule cross-year local: 00:30 Jan 1 2026 = DST');

    my $local_after = timegm_modern(0, 30, 2, 1, 1, 2026);
    is($tz->offset_for_local($local_after), $STD,
      'n-rule cross-year local: 02:30 Jan 1 2026 = STD');

    my $overlap = timegm_modern(0, 30, 1, 1, 1, 2026);
    is($tz->offset_for_local($overlap, overlap_policy => 'earlier'), $DST,
      'n-rule cross-year overlap: earlier = DST');
    is($tz->offset_for_local($overlap, overlap_policy => 'later'), $STD,
      'n-rule cross-year overlap: later = STD');
  }
}

## Cross-year: Mm.w.d rule weekday alignment varies by year
#
# "Last Monday of December" (M12.5.1) falls on Dec 30 in 2024 but
# Dec 31 in 2029. With a 26h rule time, 2029's transition crosses
# into January 2030.

{
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'STD5DST,M3.2.0/2,M12.5.1/26',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $STD = -18000;
  my $DST = -14400;

  # 2024: last Mon Dec = Dec 30, transition at Dec 31 06:00 UTC (within year)
  {
    my $before = timegm_modern(0, 0, 5, 31, 12, 2024);
    is($tz->offset_for_utc($before), $DST,
      'Mm.w.d 2024: Dec 31 05:00 UTC = DST');

    my $after = timegm_modern(0, 0, 7, 31, 12, 2024);
    is($tz->offset_for_utc($after), $STD,
      'Mm.w.d 2024: Dec 31 07:00 UTC = STD');
  }

  # 2029: last Mon Dec = Dec 31, transition at Jan 1 2030 06:00 UTC (crosses year)
  {
    my $before = timegm_modern(0, 0, 5, 1, 1, 2030);
    is($tz->offset_for_utc($before), $DST,
      'Mm.w.d 2029: Jan 1 2030 05:00 UTC = DST (before cross-year transition)');

    my $after = timegm_modern(0, 0, 7, 1, 1, 2030);
    is($tz->offset_for_utc($after), $STD,
      'Mm.w.d 2029: Jan 1 2030 07:00 UTC = STD (after cross-year transition)');
  }

  # Local: overlap at cross-year DST end (01:00-02:00 local Jan 1 2030)
  {
    my $overlap = timegm_modern(0, 30, 1, 1, 1, 2030);
    is($tz->offset_for_local($overlap, overlap_policy => 'earlier'), $DST,
      'Mm.w.d cross-year overlap: earlier = DST');
    is($tz->offset_for_local($overlap, overlap_policy => 'later'), $STD,
      'Mm.w.d cross-year overlap: later = STD');
  }
}

## Year boundary: New Year's Eve / New Year's Day

{
  # Southern hemisphere at year boundary
  my $tz = Time::TZif::POSIX->new(
    tz_string      => 'NZST-12NZDT,M9.5.0,M4.1.0/3',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  my $NZST = 43200;
  my $NZDT = 46800;

  # Dec 31 23:59 UTC -> should be NZDT (NZ summer)
  my $nye = timegm_modern(0, 59, 23, 31, 12, 2024);
  is($tz->offset_for_utc($nye), $NZDT, 'year boundary: Dec 31 23:59 UTC = NZDT');

  # Jan 1 00:00 UTC -> should be NZDT (NZ summer)
  my $nyd = timegm_modern(0, 0, 0, 1, 1, 2025);
  is($tz->offset_for_utc($nyd), $NZDT, 'year boundary: Jan 1 00:00 UTC = NZDT');
}

## Valid rule boundary values

{
  # Jn: J1 and J365 are valid
  my $tz1 = Time::TZif::POSIX->new(
    tz_string      => 'STD5DST,J1/2,J365/2',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  ok($tz1, 'Jn boundary: J1 and J365 accepted');
}

{
  # n: 0 and 365 are valid
  my $tz2 = Time::TZif::POSIX->new(
    tz_string      => 'STD5DST,0/2,365/2',
    gap_policy     => 'later',
    overlap_policy => 'earlier',
  );
  ok($tz2, 'n boundary: 0 and 365 accepted');
}

done_testing;
