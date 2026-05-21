#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Calendar', qw[ leap_year
                                    month_days
                                    valid_ymd
                                    ymd_to_dow
                                    ymd_to_rdn
                                    rdn_to_ymd
                                    rdn_to_dow
                                    resolve_century ]);
}

## leap_year

throws_ok { leap_year() }
  qr/^Usage: leap_year/,
  'leap_year: no arguments';

# divisible by 4, not by 100
ok( leap_year(2024), 'leap_year: 2024');
ok( leap_year(2028), 'leap_year: 2028');
ok( leap_year(1996), 'leap_year: 1996');

# not divisible by 4
ok(!leap_year(2023), 'leap_year: 2023');
ok(!leap_year(2025), 'leap_year: 2025');
ok(!leap_year(2019), 'leap_year: 2019');

# divisible by 100, not by 400
ok(!leap_year(1900), 'leap_year: 1900');
ok(!leap_year(2100), 'leap_year: 2100');
ok(!leap_year(2200), 'leap_year: 2200');
ok(!leap_year(2300), 'leap_year: 2300');

# divisible by 400
ok( leap_year(2000), 'leap_year: 2000');
ok( leap_year(2400), 'leap_year: 2400');
ok( leap_year(1600), 'leap_year: 1600');

# boundaries
ok(!leap_year(   1), 'leap_year: 1');
ok( leap_year(   4), 'leap_year: 4');
ok(!leap_year(9999), 'leap_year: 9999');
ok( leap_year(9996), 'leap_year: 9996');

## month_days

throws_ok { month_days() }
  qr/^Usage: month_days/,
  'month_days: no arguments';

# non-leap year
{
  my %expected = (
     1 => 31,  2 => 28,  3 => 31,  4 => 30,
     5 => 31,  6 => 30,  7 => 31,  8 => 31,
     9 => 30, 10 => 31, 11 => 30, 12 => 31,
  );
  foreach my $m (sort { $a <=> $b } keys %expected) {
    is(month_days(2023, $m), $expected{$m}, "month_days: 2023-$m");
  }
}

# leap year Feb
is(month_days(2024, 2), 29, 'month_days: 2024-02 (leap year)');
is(month_days(2000, 2), 29, 'month_days: 2000-02 (divisible by 400)');
is(month_days(1900, 2), 28, 'month_days: 1900-02 (divisible by 100, not 400)');

throws_ok { month_days(2024, 0) }
  qr/Parameter 'month' is out of range/,
  'month_days: month 0';

throws_ok { month_days(2024, 13) }
  qr/Parameter 'month' is out of range/,
  'month_days: month 13';

## valid_ymd

throws_ok { valid_ymd() }
  qr/^Usage: valid_ymd/,
  'valid_ymd: no arguments';

ok(valid_ymd(2024,  1,  1), 'valid_ymd: 2024-01-01');
ok(valid_ymd(2024,  6, 15), 'valid_ymd: 2024-06-15');
ok(valid_ymd(2024, 12, 31), 'valid_ymd: 2024-12-31');

# year boundaries
ok( valid_ymd(   1,  1,  1), 'valid_ymd: 0001-01-01');
ok( valid_ymd(9999, 12, 31), 'valid_ymd: 9999-12-31');
ok(!valid_ymd(   0,  1,  1), 'valid_ymd: year 0');
ok(!valid_ymd(10000, 1,  1), 'valid_ymd: year 10000');

# month boundaries
ok( valid_ymd(2024,  1, 15), 'valid_ymd: month 1');
ok( valid_ymd(2024, 12, 15), 'valid_ymd: month 12');
ok(!valid_ymd(2024,  0, 15), 'valid_ymd: month 0');
ok(!valid_ymd(2024, 13, 15), 'valid_ymd: month 13');

# day boundaries
ok( valid_ymd(2024,  1,  1), 'valid_ymd: day 1');
ok(!valid_ymd(2024,  1,  0), 'valid_ymd: day 0');

# days per month (non-leap year)
{
  my %mdays = (
     1 => 31,  2 => 28,  3 => 31,  4 => 30,
     5 => 31,  6 => 30,  7 => 31,  8 => 31,
     9 => 30, 10 => 31, 11 => 30, 12 => 31,
  );
  foreach my $m (sort { $a <=> $b } keys %mdays) {
    my $last = $mdays{$m};
    ok( valid_ymd(2023, $m, $last),     "valid_ymd: 2023-$m-$last (last day)");
    ok(!valid_ymd(2023, $m, $last + 1), "valid_ymd: 2023-$m-" . ($last + 1) . " (too many)");
  }
}

# leap year: Feb 29
ok( valid_ymd(2024, 2, 29), 'valid_ymd: 2024-02-29 (leap year)');
ok(!valid_ymd(2023, 2, 29), 'valid_ymd: 2023-02-29 (non-leap year)');
ok( valid_ymd(2000, 2, 29), 'valid_ymd: 2000-02-29 (divisible by 400)');
ok(!valid_ymd(1900, 2, 29), 'valid_ymd: 1900-02-29 (divisible by 100, not 400)');
ok(!valid_ymd(2100, 2, 29), 'valid_ymd: 2100-02-29 (divisible by 100, not 400)');
ok( valid_ymd(2400, 2, 29), 'valid_ymd: 2400-02-29 (divisible by 400)');

## ymd_to_rdn

throws_ok { ymd_to_rdn() }
  qr/^Usage: ymd_to_rdn/,
  'ymd_to_rdn: no arguments';

is(ymd_to_rdn(   1,  1,  1),      1, 'ymd_to_rdn: 0001-01-01');
is(ymd_to_rdn(   1,  1,  2),      2, 'ymd_to_rdn: 0001-01-02');
is(ymd_to_rdn(   1, 12, 31),    365, 'ymd_to_rdn: 0001-12-31');
is(ymd_to_rdn(   2,  1,  1),    366, 'ymd_to_rdn: 0002-01-01');
is(ymd_to_rdn(1858, 11, 17), 678576, 'ymd_to_rdn: 1858-11-17 (MJD epoch)');
is(ymd_to_rdn(1970,  1,  1), 719163, 'ymd_to_rdn: 1970-01-01 (Unix epoch)');
is(ymd_to_rdn(2000,  1,  1), 730120, 'ymd_to_rdn: 2000-01-01');
is(ymd_to_rdn(2024, 12, 24), 739244, 'ymd_to_rdn: 2024-12-24');

# consecutive days across month boundary
is(ymd_to_rdn(2024, 1, 31) + 1, ymd_to_rdn(2024, 2, 1),
  'ymd_to_rdn: Jan 31 + 1 = Feb 1');

# consecutive days across leap day
is(ymd_to_rdn(2024, 2, 29) + 1, ymd_to_rdn(2024, 3, 1),
  'ymd_to_rdn: Feb 29 + 1 = Mar 1 (leap year)');

# consecutive days across year boundary
is(ymd_to_rdn(2024, 12, 31) + 1, ymd_to_rdn(2025, 1, 1),
  'ymd_to_rdn: Dec 31 + 1 = Jan 1 next year');

# leap year has 366 days
is(ymd_to_rdn(2025, 1, 1) - ymd_to_rdn(2024, 1, 1), 366,
  'ymd_to_rdn: 2024 has 366 days');

# non-leap year has 365 days
is(ymd_to_rdn(2024, 1, 1) - ymd_to_rdn(2023, 1, 1), 365,
  'ymd_to_rdn: 2023 has 365 days');

throws_ok { ymd_to_rdn(0, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_rdn: year 0';

throws_ok { ymd_to_rdn(10000, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_rdn: year 10000';

throws_ok { ymd_to_rdn(2024, 0, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_rdn: month 0';

throws_ok { ymd_to_rdn(2024, 13, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_rdn: month 13';

throws_ok { ymd_to_rdn(2024, 1, 0) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_rdn: day 0';

throws_ok { ymd_to_rdn(2024, 1, 32) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_rdn: day 32';


## rdn_to_ymd

throws_ok { rdn_to_ymd() }
  qr/^Usage: rdn_to_ymd/,
  'rdn_to_ymd: no arguments';

# known values
is_deeply([rdn_to_ymd(      1)], [   1,  1,  1], 'rdn_to_ymd: 1 = 0001-01-01');
is_deeply([rdn_to_ymd(      2)], [   1,  1,  2], 'rdn_to_ymd: 2 = 0001-01-02');
is_deeply([rdn_to_ymd(    365)], [   1, 12, 31], 'rdn_to_ymd: 365 = 0001-12-31');
is_deeply([rdn_to_ymd(    366)], [   2,  1,  1], 'rdn_to_ymd: 366 = 0002-01-01');
is_deeply([rdn_to_ymd( 678576)], [1858, 11, 17], 'rdn_to_ymd: 678576 = 1858-11-17 (MJD epoch)');
is_deeply([rdn_to_ymd( 719163)], [1970,  1,  1], 'rdn_to_ymd: 719163 = 1970-01-01 (Unix epoch)');
is_deeply([rdn_to_ymd( 730120)], [2000,  1,  1], 'rdn_to_ymd: 730120 = 2000-01-01');
is_deeply([rdn_to_ymd( 739244)], [2024, 12, 24], 'rdn_to_ymd: 739244 = 2024-12-24');
is_deeply([rdn_to_ymd(3652059)], [9999, 12, 31], 'rdn_to_ymd: 3652059 = 9999-12-31');

# round-trip: ymd_to_rdn -> rdn_to_ymd
foreach my $date ([   1,  1,  1], [   1, 12, 31], [1970,  1,  1],
                  [2000,  2, 29], [2024,  6, 15], [9999, 12, 31]) {
  my ($y, $m, $d) = @$date;
  my $rdn = ymd_to_rdn($y, $m, $d);
  is_deeply([rdn_to_ymd($rdn)], [$y, $m, $d],
    "rdn_to_ymd: round-trip $y-$m-$d");
}

throws_ok { rdn_to_ymd(0) }
  qr/Parameter 'rdn' is out of range/,
  'rdn_to_ymd: rdn 0';

throws_ok { rdn_to_ymd(3652060) }
  qr/Parameter 'rdn' is out of range/,
  'rdn_to_ymd: rdn 3652060';

## rdn_to_dow

throws_ok { rdn_to_dow() }
  qr/^Usage: rdn_to_dow/,
  'rdn_to_dow: no arguments';

# known days (1=Mon .. 7=Sun)
# RDN 1 = 0001-01-01 = Monday
is(rdn_to_dow(      1), 1, 'rdn_to_dow: 1 (0001-01-01 Monday)');
is(rdn_to_dow(      2), 2, 'rdn_to_dow: 2 (0001-01-02 Tuesday)');
is(rdn_to_dow(      3), 3, 'rdn_to_dow: 3 (0001-01-03 Wednesday)');
is(rdn_to_dow(      4), 4, 'rdn_to_dow: 4 (0001-01-04 Thursday)');
is(rdn_to_dow(      5), 5, 'rdn_to_dow: 5 (0001-01-05 Friday)');
is(rdn_to_dow(      6), 6, 'rdn_to_dow: 6 (0001-01-06 Saturday)');
is(rdn_to_dow(      7), 7, 'rdn_to_dow: 7 (0001-01-07 Sunday)');

# epoch dates
is(rdn_to_dow( 719163), 4, 'rdn_to_dow: 719163 (1970-01-01 Thursday)');
is(rdn_to_dow( 730120), 6, 'rdn_to_dow: 730120 (2000-01-01 Saturday)');
is(rdn_to_dow( 739244), 2, 'rdn_to_dow: 739244 (2024-12-24 Tuesday)');
is(rdn_to_dow(3652059), 5, 'rdn_to_dow: 3652059 (9999-12-31 Friday)');

# consecutive days wrap Mon..Sun
{
  my $rdn = ymd_to_rdn(2024, 12, 23); # Monday
  my @expected = (1, 2, 3, 4, 5, 6, 7);
  foreach my $i (0..$#expected) {
    is(rdn_to_dow($rdn + $i), $expected[$i],
      "rdn_to_dow: consecutive day " . ($i + 1) . " = $expected[$i]");
  }
}

# consistency with ymd_to_dow
foreach my $date ([   1,  1,  1], [1970,  1,  1], [2000,  2, 29],
                  [2024,  6, 15], [2024, 12, 31], [9999, 12, 31]) {
  my ($y, $m, $d) = @$date;
  my $rdn = ymd_to_rdn($y, $m, $d);
  is(rdn_to_dow($rdn), ymd_to_dow($y, $m, $d),
    "rdn_to_dow: $y-$m-$d consistent with ymd_to_dow");
}

throws_ok { rdn_to_dow(0) }
  qr/Parameter 'rdn' is out of range/,
  'rdn_to_dow: rdn 0';

throws_ok { rdn_to_dow(3652060) }
  qr/Parameter 'rdn' is out of range/,
  'rdn_to_dow: rdn 3652060';

## ymd_to_dow

throws_ok { ymd_to_dow() }
  qr/^Usage: ymd_to_dow/,
  'ymd_to_dow: no arguments';

# known days (1=Mon .. 7=Sun)
{
  my %known = (
    '2024-12-23' => [2024, 12, 23, 1], # Monday
    '2024-12-24' => [2024, 12, 24, 2], # Tuesday
    '2024-12-25' => [2024, 12, 25, 3], # Wednesday
    '2024-12-26' => [2024, 12, 26, 4], # Thursday
    '2024-12-27' => [2024, 12, 27, 5], # Friday
    '2024-12-28' => [2024, 12, 28, 6], # Saturday
    '2024-12-29' => [2024, 12, 29, 7], # Sunday
  );
  foreach my $label (sort keys %known) {
    my ($y, $m, $d, $dow) = @{$known{$label}};
    is(ymd_to_dow($y, $m, $d), $dow, "ymd_to_dow: $label = $dow");
  }
}

# epoch dates
is(ymd_to_dow(1970,  1,  1), 4, 'ymd_to_dow: 1970-01-01 (Thursday)');
is(ymd_to_dow(2000,  1,  1), 6, 'ymd_to_dow: 2000-01-01 (Saturday)');
is(ymd_to_dow(   1,  1,  1), 1, 'ymd_to_dow: 0001-01-01 (Monday)');

# leap day
is(ymd_to_dow(2024,  2, 29), 4, 'ymd_to_dow: 2024-02-29 (Thursday)');
is(ymd_to_dow(2000,  2, 29), 2, 'ymd_to_dow: 2000-02-29 (Tuesday)');

# consistency with rdn_to_dow
foreach my $date ([2024, 1,   1], [2024, 3, 1], [2024,  6, 15],
                  [2024, 12, 31], [   1, 1, 1], [9999, 12, 31]) {
  my ($y, $m, $d) = @$date;
  is(ymd_to_dow($y, $m, $d), rdn_to_dow(ymd_to_rdn($y, $m, $d)),
    "ymd_to_dow: $y-$m-$d consistent with rdn_to_dow");
}

throws_ok { ymd_to_dow(0, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_dow: year 0';

throws_ok { ymd_to_dow(10000, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_dow: year 10000';

throws_ok { ymd_to_dow(2024, 0, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_dow: month 0';

throws_ok { ymd_to_dow(2024, 13, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_dow: month 13';

throws_ok { ymd_to_dow(2024, 1, 0) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_dow: day 0';

throws_ok { ymd_to_dow(2024, 1, 32) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_dow: day 32';

## resolve_century

throws_ok { resolve_century() }
  qr/^Usage: resolve_century/,
  'resolve_century: no arguments';

# pivot 1950
is(resolve_century( 0, 1950), 2000, 'resolve_century: 00 pivot 1950');
is(resolve_century(24, 1950), 2024, 'resolve_century: 24 pivot 1950');
is(resolve_century(49, 1950), 2049, 'resolve_century: 49 pivot 1950');
is(resolve_century(50, 1950), 1950, 'resolve_century: 50 pivot 1950');
is(resolve_century(99, 1950), 1999, 'resolve_century: 99 pivot 1950');

# pivot 2000
is(resolve_century( 0, 2000), 2000, 'resolve_century: 00 pivot 2000');
is(resolve_century(50, 2000), 2050, 'resolve_century: 50 pivot 2000');
is(resolve_century(99, 2000), 2099, 'resolve_century: 99 pivot 2000');

# pivot 2050
is(resolve_century( 0, 2050), 2100, 'resolve_century: 00 pivot 2050');
is(resolve_century(49, 2050), 2149, 'resolve_century: 49 pivot 2050');
is(resolve_century(50, 2050), 2050, 'resolve_century: 50 pivot 2050');
is(resolve_century(99, 2050), 2099, 'resolve_century: 99 pivot 2050');

# pivot 0
is(resolve_century( 0,    0),   0, 'resolve_century: 00 pivot 0');
is(resolve_century(99,    0),  99, 'resolve_century: 99 pivot 0');

# pivot at maximum
is(resolve_century( 0, 9899), 9900, 'resolve_century: 00 pivot 9899');
is(resolve_century(98, 9899), 9998, 'resolve_century: 98 pivot 9899');
is(resolve_century(99, 9899), 9899, 'resolve_century: 99 pivot 9899');

throws_ok { resolve_century(-1, 1950) }
  qr/Parameter 'year' is out of range/,
  'resolve_century: year -1';

throws_ok { resolve_century(100, 1950) }
  qr/Parameter 'year' is out of range/,
  'resolve_century: year 100';

throws_ok { resolve_century(0, -1) }
  qr/Parameter 'pivot_year' is out of range/,
  'resolve_century: pivot_year -1';

throws_ok { resolve_century(0, 9900) }
  qr/Parameter 'pivot_year' is out of range/,
  'resolve_century: pivot_year 9900';

done_testing();
