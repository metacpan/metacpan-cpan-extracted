#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

use File::Temp          qw[tempfile];
use Time::Str::Calendar qw[ymd_to_rdn];

BEGIN {
  use_ok('Time::LeapSecond', qw[ posix_tai_offset
                                 posix_to_tai
                                 tai_to_posix
                                 rdn_leap_correction
                                 load_leapseconds_tzdb
                                 load_leapseconds_iers
                                 parse_leapseconds_tzdb
                                 parse_leapseconds_iers ]);
}

sub write_temp {
  my ($fh, $path) = tempfile(UNLINK => 1);
  print({$fh} @_)
    or die qq/Couldn't write to temporary file handle: '$!'/;
  close $fh
    or die qq/Couldn't close temporary file handle: '$!'/;
  return $path;
}

sub midnight_after {
  my ($y, $m, $d) = @_;
  return (ymd_to_rdn($y, $m, $d) + 1 - 719163) * 86400;
}

## Built-in tables (whatever the BEGIN auto-load left in place)

{
  my @t = @Time::LeapSecond::TIMES;
  my @o = @Time::LeapSecond::OFFSETS;
  ok(@t > 0, 'TIMES table is populated');
  is(scalar @o, scalar @t + 1, 'OFFSETS has one entry more than TIMES');
  is($o[0], Time::LeapSecond::TAI_UTC_BASE, 'OFFSETS[0] is the base offset');
  is(scalar @Time::LeapSecond::TAI_TIMES, scalar @t, 'TAI_TIMES is parallel to TIMES');
  is(scalar @Time::LeapSecond::DAYS,      scalar @t, 'DAYS is parallel to TIMES');
  is(scalar @Time::LeapSecond::CORRECTIONS, scalar @o, 'CORRECTIONS is parallel to OFFSETS');
  is($Time::LeapSecond::CORRECTIONS[0], 0, 'CORRECTIONS[0] is the no-correction base');
  ok(defined $Time::LeapSecond::EXPIRES && $Time::LeapSecond::EXPIRES > 0,
    'EXPIRES is set after the initial load');

  my ($ascending, $unit_steps) = (1, 1);
  for my $i (1 .. $#t) {
    $ascending  &&= ($t[$i - 1] < $t[$i]);
  }
  for my $i (1 .. $#o) {
    $unit_steps &&= (abs($o[$i] - $o[$i - 1]) == 1);
  }
  ok($ascending,  'TIMES table is strictly ascending');
  ok($unit_steps, 'OFFSETS changes by exactly +/-1 at each entry');

  my $cum = $o[0];
  my $consistent = 1;
  for my $i (1 .. $#o) {
    $cum += $Time::LeapSecond::CORRECTIONS[$i];
    $consistent &&= ($cum == $o[$i]);
  }
  ok($consistent, 'OFFSETS equals the base plus the running sum of CORRECTIONS');
}

## Deterministic table: two positive leaps then one negative leap.
## Installing it makes @OFFSETS run 10, 11, 12, 11 (leading base, then one
## entry per transition).

{
  my $path = write_temp(
    "# synthetic leap seconds\n",
    "\n",
    "Leap\t1972\tJun\t30\t23:59:60\t+\tS\n",
    "Leap\t1972\tDec\t31\t23:59:60\t+\tS\n",
    "Leap\t1973\tDec\t31\t23:59:59\t-\tS\n",
    "#expires 1735344000\n",
  );
  my $n = load_leapseconds_tzdb($path);
  is($n, 3, 'load_leapseconds_tzdb: returns number of entries');
  is($Time::LeapSecond::EXPIRES, 1735344000,
    'load_leapseconds_tzdb: sets EXPIRES from the file');
  is_deeply([@Time::LeapSecond::OFFSETS], [10, 11, 12, 11],
    'negative leap second lowers the cumulative offset (OFFSETS[0] is the base)');
  is_deeply([@Time::LeapSecond::CORRECTIONS], [0, 1, 1, -1],
    'CORRECTIONS has the leading 0 base then one delta per transition');

  my $e1 = midnight_after(1972,  6, 30);   # 1972-07-01
  my $e2 = midnight_after(1972, 12, 31);   # 1973-01-01
  my $e3 = midnight_after(1973, 12, 31);   # 1974-01-01

  ## posix_tai_offset (TAI-UTC offset)
  is(posix_tai_offset(0),       10, 'posix_tai_offset: before first leap is base 10');
  is(posix_tai_offset($e1 - 1), 10, 'posix_tai_offset: one second before first is 10');
  is(posix_tai_offset($e1),     11, 'posix_tai_offset: at first positive leap is 11');
  is(posix_tai_offset($e2),     12, 'posix_tai_offset: at second positive leap is 12');
  is(posix_tai_offset($e3 - 1), 12, 'posix_tai_offset: just before negative leap is 12');
  is(posix_tai_offset($e3),     11, 'posix_tai_offset: at negative leap drops to 11');

  ## posix_to_tai / tai_to_posix round-trips for real instants. Note $e3 - 1 is
  ## the second removed by the negative leap (23:59:59 never occurs), so it is
  ## a phantom epoch that collapses onto the boundary and is excluded here.
  my $rt = 1;
  for my $u ($e1 - 1, $e1, $e2, $e3 - 2, $e3, $e3 + 100) {
    $rt &&= (tai_to_posix(posix_to_tai($u)) == $u);
  }
  ok($rt, 'posix_to_tai/tai_to_posix round-trip across positive and negative leaps');
  is(posix_to_tai($e3), $e3 + 11, 'posix_to_tai: uses the lowered offset after negative leap');

  ## Leap-second fold direction (matches tz/TZif). Positive leap: the
  ## inserted 23:59:60 folds onto the preceding 23:59:59, so both share the
  ## same POSIX second. TAI_TIMES uses the smaller (old) offset.
  is($Time::LeapSecond::TAI_TIMES[0], $e1 + 10,
    'TAI_TIMES uses the smaller (old) offset at a positive leap');
  is(tai_to_posix($e1 + 9),  $e1 - 1, 'positive leap: real 23:59:59 maps to e1-1');
  is(tai_to_posix($e1 + 10), $e1 - 1, 'positive leap: inserted 23:59:60 folds onto 23:59:59');

  ## Negative leap: 23:59:59 is removed, so its POSIX value is a gap; the last
  ## real second (23:59:58) and the following midnight bracket it. TAI_TIMES
  ## uses the smaller (new) offset.
  is($Time::LeapSecond::TAI_TIMES[2], $e3 + 11,
    'TAI_TIMES uses the smaller (new) offset at a negative leap');
  is(tai_to_posix($e3 + 10), $e3 - 2, 'negative leap: last real second is 23:59:58');
  is(tai_to_posix($e3 + 11), $e3,     'negative leap: midnight maps cleanly (e3-1 is a gap)');

  ## rdn_leap_correction: +1 for positive, -1 for negative, 0 otherwise
  is(rdn_leap_correction(ymd_to_rdn(1972,  6, 30)),  1, 'rdn_leap_correction: positive leap day is +1');
  is(rdn_leap_correction(ymd_to_rdn(1972, 12, 31)),  1, 'rdn_leap_correction: positive leap day is +1');
  is(rdn_leap_correction(ymd_to_rdn(1973, 12, 31)), -1, 'rdn_leap_correction: negative leap day is -1');
  is(rdn_leap_correction(ymd_to_rdn(1972,  6, 29)),  0, 'rdn_leap_correction: ordinary day is 0');
  is(rdn_leap_correction(ymd_to_rdn(2000,  1,  1)),  0, 'rdn_leap_correction: unrelated day is 0');
}

## Usage errors

throws_ok { posix_tai_offset() }    qr/^Usage: posix_tai_offset/,    'posix_tai_offset: no args';
throws_ok { posix_to_tai() }        qr/^Usage: posix_to_tai/,        'posix_to_tai: no args';
throws_ok { tai_to_posix() }        qr/^Usage: tai_to_posix/,        'tai_to_posix: no args';
throws_ok { rdn_leap_correction() } qr/^Usage: rdn_leap_correction/, 'rdn_leap_correction: no args';

## parse_leapseconds_tzdb

throws_ok { parse_leapseconds_tzdb() }
  qr/^Usage: parse_leapseconds_tzdb/,
  'parse_leapseconds_tzdb: no arguments';

throws_ok { parse_leapseconds_tzdb('/this/path/does/not/exist') }
  qr/could not open/,
  'parse_leapseconds_tzdb: missing file croaks';

{
  my $path = write_temp(
    "# comment\n",
    "\n",
    "Leap\t1972\tJun\t30\t23:59:60\t+\tS\n",
    "Leap\t1972\tDec\t31\t23:59:60\t+\tS\n",
    "#Expires 1735344000\n",
  );
  my ($days, $corrections, $expires) = parse_leapseconds_tzdb($path);
  is_deeply($days, [ ymd_to_rdn(1972,  6, 30), 
                     ymd_to_rdn(1972, 12, 31) ],
    'parse_leapseconds_tzdb: returns leap days as RDNs');
  is_deeply($corrections, [1, 1],
    'parse_leapseconds_tzdb: returns per-transition corrections');
  is($expires, 1735344000,
    'parse_leapseconds_tzdb: returns the expiration timestamp');
}

{
  # Negative leap seconds are now supported, not rejected.
  my $path = write_temp(
    "Leap\t2030\tDec\t31\t23:59:59\t-\tS\n",
    "#expires 1924905600\n",
  );
  my ($days, $corrections, $expires) = parse_leapseconds_tzdb($path);
  is_deeply($days, [ymd_to_rdn(2030, 12, 31)],
    'parse_leapseconds_tzdb: negative leap day as RDN');
  is_deeply($corrections, [-1],
    'parse_leapseconds_tzdb: negative leap is a -1 correction');
  is($expires, 1924905600,
    'parse_leapseconds_tzdb: expiration extracted from negative-leap fixture');
}

throws_ok {
  parse_leapseconds_tzdb(write_temp(
    "Leap\t1972\tJun\t30\t23:59:60\t+\tS\n",
    "# no expires line here\n",
  ))
} qr/no expiration found/,
  'parse_leapseconds_tzdb: missing expires line croaks';

throws_ok { parse_leapseconds_tzdb(write_temp("Leap not a real line\n")) }
  qr/malformed line/,
  'parse_leapseconds_tzdb: malformed line croaks';

throws_ok { parse_leapseconds_tzdb(write_temp("Leap\t1972\tJun\t30\t23:59:59\t+\tS\n")) }
  qr/unexpected leap second time/,
  'parse_leapseconds_tzdb: positive leap with wrong time croaks';

throws_ok { parse_leapseconds_tzdb(write_temp("Leap\t1972\tJun\t30\t23:59:60\t-\tS\n")) }
  qr/unexpected leap second time/,
  'parse_leapseconds_tzdb: negative leap with wrong time croaks';

throws_ok {
  parse_leapseconds_tzdb(write_temp(
    "Leap\t1973\tDec\t31\t23:59:60\t+\tS\n",
    "Leap\t1972\tJun\t30\t23:59:60\t+\tS\n",   # earlier date after a later one
  ))
} qr/out of order/,
  'parse_leapseconds_tzdb: out-of-order entries croak';

## parse_leapseconds_iers

throws_ok { parse_leapseconds_iers() }
  qr/^Usage: parse_leapseconds_iers/,
  'parse_leapseconds_iers: no arguments';

throws_ok { parse_leapseconds_iers('/this/path/does/not/exist') }
  qr/could not open/,
  'parse_leapseconds_iers: missing file croaks';

{
  # NTP epoch = Unix + 2208988800. Base row (offset 10) is dropped; the
  # remaining rows become the transitions. Final row is a negative leap.
  my $path = write_temp(
    "#\$\t3913697179\n",
    "#\@\t3944332800\n",
    "2272060800\t10\t# 1 Jan 1972 (base)\n",
    "2287785600\t11\t# 1 Jul 1972\n",
    "2303683200\t12\t# 1 Jan 1973\n",
    "2335219200\t11\t# 1 Jan 1974 (negative)\n",
  );
  my ($days, $corrections, $expires) = parse_leapseconds_iers($path);
  is_deeply($days, [ ymd_to_rdn(1972,  6, 30), 
                     ymd_to_rdn(1972, 12, 31),
                     ymd_to_rdn(1973, 12, 31) ],
    'parse_leapseconds_iers: NTP epochs converted to leap-day RDNs, base row dropped');
  is_deeply($corrections, [1, 1, -1],
    'parse_leapseconds_iers: absolute offsets turned into corrections, negative handled');
  # #@ 3944332800 NTP -> 3944332800 - 2208988800 = 1735344000 POSIX
  is($expires, 1735344000,
    'parse_leapseconds_iers: expiration extracted from #@ line and converted to POSIX');
}

throws_ok {
  parse_leapseconds_iers(write_temp(
    "2272060800\t10\n",   # base
    "2287785600\t11\n",   # 1 Jul 1972
  ))
} qr/no expiration found/,
  'parse_leapseconds_iers: missing #@ line croaks';

throws_ok { parse_leapseconds_iers(write_temp("not numbers here\n")) }
  qr/malformed line/,
  'parse_leapseconds_iers: malformed line croaks';

throws_ok {
  parse_leapseconds_iers(write_temp(
    "2272060800\t10\n",
    "2287785600\t13\n",   # +3 jump is not a valid leap step
  ))
} qr/unexpected offset step/,
  'parse_leapseconds_iers: non-unit offset step croaks';

throws_ok {
  parse_leapseconds_iers(write_temp(
    "2272060800\t10\n",   # base
    "2303683200\t11\n",   # 1973-01-01
    "2287785600\t12\n",   # 1972-07-01 (earlier) -> out of order
  ))
} qr/out of order at NTP 2287785600/,
  'parse_leapseconds_iers: out-of-order entries croak, message names the NTP stamp';

throws_ok {
  parse_leapseconds_iers(write_temp("2287785600\t11\n"))   # first row not the base
} qr/does not start at the base offset/,
  'parse_leapseconds_iers: table not starting at the base offset croaks';

throws_ok {
  parse_leapseconds_iers(write_temp(
    "2272060800\t10\n",   # base (midnight)
    "2287785601\t11\n",   # one second past midnight
  ))
} qr/NTP 2287785601 is not a UTC midnight/,
  'parse_leapseconds_iers: non-midnight epoch croaks, message names the NTP stamp';

## Cross-format agreement on the live system files (if present)

SKIP: {
  my $dir = Time::Str::Util::find_tzdb_directory();
  skip "no TZDB directory found", 1 unless defined $dir;
  my ($tzdb, $iers) = ("$dir/leapseconds", "$dir/leap-seconds.list");
  skip "system leapseconds/leap-seconds.list not both present", 1
    unless -f $tzdb && -f $iers;

  my ($td, $tc, $te) = parse_leapseconds_tzdb($tzdb);
  my ($id, $ic, $ie) = parse_leapseconds_iers($iers);
  ok(eq_array($td, $id) && eq_array($tc, $ic),
    'parse_leapseconds_tzdb and parse_leapseconds_iers agree on system files (days/corrections)');
  is($te, $ie,
    'parse_leapseconds_tzdb and parse_leapseconds_iers agree on system files (expires)');
}

## Loaders: error policy

throws_ok { load_leapseconds_tzdb(1, 2) }
  qr/^Usage: load_leapseconds_tzdb/,
  'load_leapseconds_tzdb: too many arguments';

throws_ok { load_leapseconds_iers(1, 2) }
  qr/^Usage: load_leapseconds_iers/,
  'load_leapseconds_iers: too many arguments';

# An explicit missing path is an error (not a silent fallback).
throws_ok { load_leapseconds_tzdb('/this/path/does/not/exist') }
  qr/could not open/,
  'load_leapseconds_tzdb: explicit missing path croaks';

throws_ok { load_leapseconds_iers('/this/path/does/not/exist') }
  qr/could not open/,
  'load_leapseconds_iers: explicit missing path croaks';

# A malformed explicit file is an error and leaves the table intact.
{
  my @before = @Time::LeapSecond::TIMES;
  throws_ok { load_leapseconds_tzdb(write_temp("Leap garbage line\n")) }
    qr/malformed line/,
    'load_leapseconds_tzdb: malformed file croaks';
  is_deeply([@Time::LeapSecond::TIMES], \@before,
    'load_leapseconds_tzdb: failed load leaves table intact');
}

# Auto mode (no argument) must not die, regardless of whether a system file
# exists; it returns a count or undef.
{
  my $r = eval { load_leapseconds_tzdb() };
  ok(!$@, 'load_leapseconds_tzdb: auto mode does not die');
  ok(!defined $r || $r > 0, 'load_leapseconds_tzdb: auto mode returns undef or a count');
}

done_testing;
