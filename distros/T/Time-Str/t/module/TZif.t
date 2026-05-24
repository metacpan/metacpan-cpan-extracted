#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[find_tzdir throws_ok];

my $TZDIR = find_tzdir();

# Skip all tests if zoneinfo is not available
unless (defined $TZDIR) {
  plan skip_all => "zoneinfo directory not available";
}

use_ok('Time::TZif');

## Constructor

throws_ok { Time::TZif->new() }
  qr/Usage:/,
  'new: no arguments';

throws_ok { Time::TZif->new(filename => '/nonexistent/path') }
  qr/Unable to parse TZif: could not open/,
  'new: nonexistent file';

throws_ok { Time::TZif->new(filename => "$TZDIR/UTC", bogus => 1) }
  qr/Unrecognised named parameter: 'bogus'/,
  'new: unknown parameter';

throws_ok { Time::TZif->new(filename => "$TZDIR/UTC", gap_policy => 'invalid') }
  qr/Invalid policy value for the parameter 'gap_policy'/,
  'new: invalid gap_policy policy';

throws_ok { Time::TZif->new(filename => "$TZDIR/UTC", overlap_policy => 'invalid') }
  qr/Invalid policy value for the parameter 'overlap_policy'/,
  'new: invalid overlap_policy policy';

## Constructor defaults

{
  my $tz = Time::TZif->new(filename => "$TZDIR/UTC");
  is($tz->gap_policy,     'reject', 'default gap_policy is reject');
  is($tz->overlap_policy, 'reject', 'default overlap_policy is reject');
}

{
  my $tz = Time::TZif->new(
    filename   => "$TZDIR/UTC",
    gap_policy     => 'later',
    overlap_policy => 'std',
  );
  is($tz->gap_policy,     'later', 'custom gap_policy preserved');
  is($tz->overlap_policy, 'std',   'custom overlap_policy preserved');
}

## UTC timezone (no DST transitions)

{
  my $utc = Time::TZif->new(filename => "$TZDIR/UTC");
  isa_ok($utc, 'Time::TZif');
  is($utc->filename, "$TZDIR/UTC", 'filename accessor');
  is($utc->offset_for_utc(0), 0, 'UTC: offset_for_utc at epoch 0');
  is($utc->offset_for_utc(1_000_000_000), 0, 'UTC: offset_for_utc at 1e9');
  is($utc->offset_for_local(0), 0, 'UTC: offset_for_local at epoch 0');
  is($utc->offset_for_local(1_000_000_000), 0, 'UTC: offset_for_local at 1e9');

  my @info = $utc->type_info_for_utc(0);
  is($info[0], 0, 'UTC: type_info offset');
  is($info[1], 0, 'UTC: type_info is_dst');
  is($info[2], 'UTC', 'UTC: type_info abbreviation');
}

## America/New_York (EST/EDT with spring-forward and fall-back)

SKIP: {
  skip "America/New_York not available", 60
    unless -f "$TZDIR/America/New_York";

  my $tz = Time::TZif->new(filename => "$TZDIR/America/New_York");
  isa_ok($tz, 'Time::TZif');

  # Known constants
  my $EST = -18000;  # UTC-5
  my $EDT = -14400;  # UTC-4

  # offset_for_utc tests

  # 2024-01-15 12:00:00 UTC (winter, should be EST)
  {
    use Time::Local;
    my $utc = timegm(0, 0, 12, 15, 0, 2024);
    is($tz->offset_for_utc($utc), $EST, 'offset_for_utc: winter EST');

    my @info = $tz->type_info_for_utc($utc);
    is($info[0], $EST, 'type_info_for_utc: winter offset');
    is($info[1], 0, 'type_info_for_utc: winter is_dst=0');
    is($info[2], 'EST', 'type_info_for_utc: winter abbreviation');
  }

  # 2024-07-15 12:00:00 UTC (summer, should be EDT)
  {
    my $utc = timegm(0, 0, 12, 15, 6, 2024);
    is($tz->offset_for_utc($utc), $EDT, 'offset_for_utc: summer EDT');

    my @info = $tz->type_info_for_utc($utc);
    is($info[0], $EDT, 'type_info_for_utc: summer offset');
    is($info[1], 1, 'type_info_for_utc: summer is_dst=1');
    is($info[2], 'EDT', 'type_info_for_utc: summer abbreviation');
  }

  # Spring forward 2024: 2024-03-10 07:00:00 UTC
  # Clocks jump from 02:00 EST to 03:00 EDT
  # Gap: local times 02:00:00-02:59:59 do not exist

  my $spring_utc = timegm(0, 0, 7, 10, 2, 2024);  # 1710054000

  # offset_for_utc at the transition boundary
  is($tz->offset_for_utc($spring_utc - 1), $EST,
    'offset_for_utc: 1s before spring forward = EST');
  is($tz->offset_for_utc($spring_utc), $EDT,
    'offset_for_utc: at spring forward = EDT');

  # offset_for_local: unambiguous times around the spring gap
  {
    my $before_gap = timegm(59, 59, 1, 10, 2, 2024);
    is($tz->offset_for_local($before_gap), $EST,
      'offset_for_local: 01:59:59 before spring gap = EST');
  }
  {
    my $after_gap = timegm(0, 0, 3, 10, 2, 2024);
    is($tz->offset_for_local($after_gap), $EDT,
      'offset_for_local: 03:00:00 after spring gap = EDT');
  }

  # offset_for_local: non-existing time in the gap
  {
    my $in_gap = timegm(0, 30, 2, 10, 2, 2024);

    # Default gap_policy is 'reject'
    throws_ok { $tz->offset_for_local($in_gap) }
      qr/Unable to resolve local time: non-existing time \(gap\)/,
      'offset_for_local: gap default (reject)';

    throws_ok { $tz->offset_for_local($in_gap, gap_policy => 'reject') }
      qr/Unable to resolve local time: non-existing time \(gap\)/,
      'offset_for_local: gap reject';

    is($tz->offset_for_local($in_gap, gap_policy => 'earlier'), $EST,
      'offset_for_local: gap earlier = EST (pre-transition)');

    is($tz->offset_for_local($in_gap, gap_policy => 'later'), $EDT,
      'offset_for_local: gap later = EDT (post-transition)');

    is($tz->offset_for_local($in_gap, gap_policy => 'std'), $EST,
      'offset_for_local: gap std = EST');

    is($tz->offset_for_local($in_gap, gap_policy => 'dst'), $EDT,
      'offset_for_local: gap dst = EDT');
  }

  # Fall back 2024: 2024-11-03 06:00:00 UTC
  # Clocks fall from 02:00 EDT to 01:00 EST
  # Overlap: local times 01:00:00-01:59:59 occur twice

  my $fall_utc = timegm(0, 0, 6, 3, 10, 2024);  # 1730613600

  # offset_for_utc at the transition boundary
  is($tz->offset_for_utc($fall_utc - 1), $EDT,
    'offset_for_utc: 1s before fall back = EDT');
  is($tz->offset_for_utc($fall_utc), $EST,
    'offset_for_utc: at fall back = EST');

  # offset_for_local: unambiguous times around the fall overlap
  {
    my $before_overlap = timegm(59, 59, 0, 3, 10, 2024);
    is($tz->offset_for_local($before_overlap), $EDT,
      'offset_for_local: 00:59:59 before fall overlap = EDT');
  }
  {
    my $after_overlap = timegm(0, 0, 2, 3, 10, 2024);
    is($tz->offset_for_local($after_overlap), $EST,
      'offset_for_local: 02:00:00 after fall overlap = EST');
  }

  # offset_for_local: ambiguous time in the overlap
  {
    my $in_overlap = timegm(0, 30, 1, 3, 10, 2024);

    # Default overlap_policy is 'reject'
    throws_ok { $tz->offset_for_local($in_overlap) }
      qr/Unable to resolve local time: ambiguous time \(overlap\)/,
      'offset_for_local: overlap default (reject)';

    is($tz->offset_for_local($in_overlap, overlap_policy => 'later'), $EST,
      'offset_for_local: overlap later = EST (post-transition)');

    is($tz->offset_for_local($in_overlap, overlap_policy => 'earlier'), $EDT,
      'offset_for_local: overlap earlier = EDT (pre-transition)');

    is($tz->offset_for_local($in_overlap, overlap_policy => 'std'), $EST,
      'offset_for_local: overlap std = EST');

    is($tz->offset_for_local($in_overlap, overlap_policy => 'dst'), $EDT,
      'offset_for_local: overlap dst = EDT');

    throws_ok { $tz->offset_for_local($in_overlap, overlap_policy => 'reject') }
      qr/Unable to resolve local time: ambiguous time \(overlap\)/,
      'offset_for_local: overlap reject';
  }

  # type_info_for_local

  {
    my $winter = timegm(0, 0, 12, 15, 0, 2024);
    my @info = $tz->type_info_for_local($winter);
    is($info[0], $EST, 'type_info_for_local: winter offset');
    is($info[1], 0, 'type_info_for_local: winter is_dst=0');
    is($info[2], 'EST', 'type_info_for_local: winter abbreviation');
  }
  {
    my $summer = timegm(0, 0, 12, 15, 6, 2024);
    my @info = $tz->type_info_for_local($summer);
    is($info[0], $EDT, 'type_info_for_local: summer offset');
    is($info[1], 1, 'type_info_for_local: summer is_dst=1');
    is($info[2], 'EDT', 'type_info_for_local: summer abbreviation');
  }

  # Edge cases: gap boundaries

  {
    my $gap_start = timegm(0, 0, 2, 10, 2, 2024);
    throws_ok { $tz->offset_for_local($gap_start) }
      qr/Unable to resolve local time: non-existing time \(gap\)/,
      'offset_for_local: exactly at gap start (02:00:00) = non-existing';
  }
  {
    my $gap_end = timegm(0, 0, 3, 10, 2, 2024);
    is($tz->offset_for_local($gap_end), $EDT,
      'offset_for_local: exactly at gap end (03:00:00) = EDT');
  }

  # Edge cases: overlap boundaries

  {
    my $overlap_start = timegm(0, 0, 1, 3, 10, 2024);
    is($tz->offset_for_local($overlap_start, overlap_policy => 'earlier'), $EDT,
      'offset_for_local: exactly at overlap start (01:00:00) earlier = EDT');
    is($tz->offset_for_local($overlap_start, overlap_policy => 'later'), $EST,
      'offset_for_local: exactly at overlap start (01:00:00) later = EST');
  }
  {
    my $overlap_end = timegm(0, 0, 2, 3, 10, 2024);
    is($tz->offset_for_local($overlap_end), $EST,
      'offset_for_local: exactly at overlap end (02:00:00) = EST (unambiguous)');
  }

  # Constructor defaults applied to offset_for_local

  {
    my $tz_custom = Time::TZif->new(
      filename   => "$TZDIR/America/New_York",
      gap_policy     => 'later',
      overlap_policy => 'earlier',
    );

    my $in_gap = timegm(0, 30, 2, 10, 2, 2024);
    is($tz_custom->offset_for_local($in_gap), $EDT,
      'constructor gap_policy=later: gap returns EDT');

    my $in_overlap = timegm(0, 30, 1, 3, 10, 2024);
    is($tz_custom->offset_for_local($in_overlap), $EDT,
      'constructor overlap_policy=earlier: overlap returns EDT');

    # Per-call override takes precedence
    is($tz_custom->offset_for_local($in_gap, gap_policy => 'earlier'), $EST,
      'per-call gap_policy overrides constructor default');
    is($tz_custom->offset_for_local($in_overlap, overlap_policy => 'later'), $EST,
      'per-call overlap_policy overrides constructor default');
  }
}

## Europe/Stockholm (CET/CEST, positive offsets)

SKIP: {
  skip "Europe/Stockholm not available", 10
    unless -f "$TZDIR/Europe/Stockholm";

  my $tz = Time::TZif->new(filename => "$TZDIR/Europe/Stockholm");

  my $CET  = 3600;   # UTC+1
  my $CEST = 7200;   # UTC+2

  # 2024-01-15 12:00:00 UTC (winter, CET)
  {
    my $utc = timegm(0, 0, 12, 15, 0, 2024);
    is($tz->offset_for_utc($utc), $CET, 'Stockholm: winter CET');
  }

  # 2024-07-15 12:00:00 UTC (summer, CEST)
  {
    my $utc = timegm(0, 0, 12, 15, 6, 2024);
    is($tz->offset_for_utc($utc), $CEST, 'Stockholm: summer CEST');
  }

  # Spring forward 2024: 2024-03-31 01:00:00 UTC
  {
    my $spring = timegm(0, 0, 1, 31, 2, 2024);
    is($tz->offset_for_utc($spring - 1), $CET,  'Stockholm: 1s before spring = CET');
    is($tz->offset_for_utc($spring),     $CEST, 'Stockholm: at spring = CEST');

    my $in_gap = timegm(0, 30, 2, 31, 2, 2024);
    throws_ok { $tz->offset_for_local($in_gap) }
      qr/Unable to resolve local time: non-existing time \(gap\)/,
      'Stockholm: spring gap reject';

    is($tz->offset_for_local($in_gap, gap_policy => 'earlier'), $CET,
      'Stockholm: spring gap earlier = CET');
    is($tz->offset_for_local($in_gap, gap_policy => 'later'), $CEST,
      'Stockholm: spring gap later = CEST');
  }

  # Fall back 2024: 2024-10-27 01:00:00 UTC
  {
    my $fall = timegm(0, 0, 1, 27, 9, 2024);
    is($tz->offset_for_utc($fall - 1), $CEST, 'Stockholm: 1s before fall = CEST');
    is($tz->offset_for_utc($fall),     $CET,  'Stockholm: at fall = CET');

    my $in_overlap = timegm(0, 30, 2, 27, 9, 2024);
    is($tz->offset_for_local($in_overlap, overlap_policy => 'std'), $CET,
      'Stockholm: fall overlap std = CET');
  }
}

## Parameter validation

{
  SKIP: {
    skip "UTC not available", 3 unless -f "$TZDIR/UTC";
    my $tz = Time::TZif->new(filename => "$TZDIR/UTC");

    throws_ok { $tz->offset_for_local(0, overlap_policy => 'invalid') }
      qr/Invalid policy value for the parameter 'overlap_policy'/,
      'offset_for_local: invalid overlap_policy policy';

    throws_ok { $tz->offset_for_local(0, gap_policy => 'invalid') }
      qr/Invalid policy value for the parameter 'gap_policy'/,
      'offset_for_local: invalid gap_policy policy';

    throws_ok { $tz->offset_for_local(0, bogus => 1) }
      qr/Unrecognised named parameter: 'bogus'/,
      'offset_for_local: unknown parameter';
  }
}

done_testing;
