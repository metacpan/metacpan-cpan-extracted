#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Token', qw[ parse_day
                                 parse_day_name
                                 parse_month
                                 parse_meridiem
                                 parse_tz_offset ]);
}

# parse_day

throws_ok { parse_day() }
  qr/^Usage: parse_day/,
  'parse_day: no arguments';

# numeric without leading zero
foreach my $d (1..9) {
  is(parse_day("$d"), $d, "parse_day: '$d'");
}

# numeric with leading zero
foreach my $d (1..9) {
  my $s = sprintf('%02d', $d);
  is(parse_day($s), $d, "parse_day: '$s'");
}

# two-digit (10-31)
foreach my $d (10..31) {
  is(parse_day("$d"), $d, "parse_day: '$d'");
}

{
  my %ordinals = (
    '1st'  =>  1, '2nd'  =>  2, '3rd'  =>  3,
    '4th'  =>  4, '5th'  =>  5, '6th'  =>  6,
    '7th'  =>  7, '8th'  =>  8, '9th'  =>  9,
    '10th' => 10, '11th' => 11, '12th' => 12,
    '13th' => 13, '14th' => 14, '15th' => 15,
    '16th' => 16, '17th' => 17, '18th' => 18,
    '19th' => 19, '20th' => 20, '21st' => 21,
    '22nd' => 22, '23rd' => 23, '24th' => 24,
    '25th' => 25, '26th' => 26, '27th' => 27,
    '28th' => 28, '29th' => 29, '30th' => 30,
    '31st' => 31,
  );
  while (my ($s, $v) = each %ordinals) {
    is(parse_day($s), $v, "parse_day: '$s'");
  }
}

# case insensitive ordinals
is(parse_day('1ST'),  1, "parse_day: '1ST'");
is(parse_day('2ND'),  2, "parse_day: '2ND'");
is(parse_day('3RD'),  3, "parse_day: '3RD'");
is(parse_day('21St'), 21, "parse_day: '21St'");

throws_ok { parse_day('0') }
  qr/Unable to parse: day is invalid/,
  'parse_day: 0';

throws_ok { parse_day('32') }
  qr/Unable to parse: day is invalid/,
  'parse_day: 32';

throws_ok { parse_day('00') }
  qr/Unable to parse: day is invalid/,
  'parse_day: 00';

throws_ok { parse_day('') }
  qr/Unable to parse: day is invalid/,
  'parse_day: empty string';

throws_ok { parse_day('abc') }
  qr/Unable to parse: day is invalid/,
  'parse_day: non-numeric';

throws_ok { parse_day('32nd') }
  qr/Unable to parse: day is invalid/,
  'parse_day: 32nd';

# parse_month

throws_ok { parse_month() }
  qr/^Usage: parse_month/,
  'parse_month: no arguments';

foreach my $m (1..9) {
  is(parse_month("$m"), $m, "parse_month: '$m'");
}

foreach my $m (1..9) {
  my $s = sprintf('%02d', $m);
  is(parse_month($s), $m, "parse_month: '$s'");
}

foreach my $m (10..12) {
  is(parse_month("$m"), $m, "parse_month: '$m'");
}

{
  my %abbrev = (
    Jan =>  1, Feb =>  2, Mar =>  3, Apr =>  4,
    May =>  5, Jun =>  6, Jul =>  7, Aug =>  8,
    Sep =>  9, Oct => 10, Nov => 11, Dec => 12,
  );
  foreach my $s (sort keys %abbrev) {
    is(parse_month($s), $abbrev{$s}, "parse_month: '$s'");
  }
}

{
  my %full = (
    January   =>  1, February  =>  2, March     =>  3, April    =>  4,
    May       =>  5, June      =>  6, July      =>  7, August   =>  8,
    September =>  9, October   => 10, November  => 11, December => 12,
  );
  foreach my $s (sort keys %full) {
    is(parse_month($s), $full{$s}, "parse_month: '$s'");
  }
}

is(parse_month('JAN'),       1, "parse_month: 'JAN'");
is(parse_month('january'),   1, "parse_month: 'january'");
is(parse_month('SEPTEMBER'), 9, "parse_month: 'SEPTEMBER'");

is(parse_month('sept'), 9, "parse_month: 'sept'");
is(parse_month('Sept'), 9, "parse_month: 'Sept'");

{
  my %roman = (
    I   =>  1, II  =>  2, III  =>  3, IV   =>  4,
    V   =>  5, VI  =>  6, VII  =>  7, VIII =>  8,
    IX  =>  9, X   => 10, XI   => 11, XII  => 12,
  );
  foreach my $s (sort keys %roman) {
    is(parse_month($s), $roman{$s}, "parse_month: '$s'");
  }
}

is(parse_month('i'),    1, "parse_month: 'i'");
is(parse_month('iv'),   4, "parse_month: 'iv'");
is(parse_month('viii'), 8, "parse_month: 'viii'");
is(parse_month('xii'), 12, "parse_month: 'xii'");

throws_ok { parse_month('0') }
  qr/Unable to parse: month is invalid/,
  'parse_month: 0';

throws_ok { parse_month('13') }
  qr/Unable to parse: month is invalid/,
  'parse_month: 13';

throws_ok { parse_month('00') }
  qr/Unable to parse: month is invalid/,
  'parse_month: 00';

throws_ok { parse_month('') }
  qr/Unable to parse: month is invalid/,
  'parse_month: empty string';

throws_ok { parse_month('Foo') }
  qr/Unable to parse: month is invalid/,
  'parse_month: Foo';

throws_ok { parse_month('XIII') }
  qr/Unable to parse: month is invalid/,
  'parse_month: XIII';

# parse_day_name

throws_ok { parse_day_name() }
  qr/^Usage: parse_day_name/,
  'parse_day_name: no arguments';

{
  my %abbrev = (
    Mon => 1, Tue => 2, Wed => 3, Thu => 4,
    Fri => 5, Sat => 6, Sun => 7,
  );
  foreach my $s (sort keys %abbrev) {
    is(parse_day_name($s), $abbrev{$s}, "parse_day_name: '$s'");
  }
}

{
  my %full = (
    Monday => 1, Tuesday  => 2, Wednesday => 3, Thursday => 4,
    Friday => 5, Saturday => 6, Sunday    => 7,
  );
  foreach my $s (sort keys %full) {
    is(parse_day_name($s), $full{$s}, "parse_day_name: '$s'");
  }
}

is(parse_day_name('Tues'),  2, "parse_day_name: 'Tues'");
is(parse_day_name('Thurs'), 4, "parse_day_name: 'Thurs'");

is(parse_day_name('MON'),      1, "parse_day_name: 'MON'");
is(parse_day_name('monday'),   1, "parse_day_name: 'monday'");
is(parse_day_name('FRIDAY'),   5, "parse_day_name: 'FRIDAY'");
is(parse_day_name('tues'),     2, "parse_day_name: 'tues'");
is(parse_day_name('thurs'),    4, "parse_day_name: 'thurs'");

throws_ok { parse_day_name('') }
  qr/Unable to parse: day name is invalid/,
  'parse_day_name: empty string';

throws_ok { parse_day_name('Foo') }
  qr/Unable to parse: day name is invalid/,
  'parse_day_name: Foo';

throws_ok { parse_day_name('Su') }
  qr/Unable to parse: day name is invalid/,
  'parse_day_name: Su (too short)';

throws_ok { parse_day_name('Th') }
  qr/Unable to parse: day name is invalid/,
  'parse_day_name: Th (too short)';

# parse_meridiem

throws_ok { parse_meridiem() }
  qr/^Usage: parse_meridiem/,
  'parse_meridiem: no arguments';

is(parse_meridiem('am'),    0, "parse_meridiem: 'am'");
is(parse_meridiem('AM'),    0, "parse_meridiem: 'AM'");
is(parse_meridiem('Am'),    0, "parse_meridiem: 'Am'");
is(parse_meridiem('a.m.'),  0, "parse_meridiem: 'a.m.'");
is(parse_meridiem('A.M.'),  0, "parse_meridiem: 'A.M.'");

is(parse_meridiem('pm'),   12, "parse_meridiem: 'pm'");
is(parse_meridiem('PM'),   12, "parse_meridiem: 'PM'");
is(parse_meridiem('Pm'),   12, "parse_meridiem: 'Pm'");
is(parse_meridiem('p.m.'), 12, "parse_meridiem: 'p.m.'");
is(parse_meridiem('P.M.'), 12, "parse_meridiem: 'P.M.'");

throws_ok { parse_meridiem('') }
  qr/Unable to parse: meridiem is invalid/,
  'parse_meridiem: empty string';

throws_ok { parse_meridiem('a') }
  qr/Unable to parse: meridiem is invalid/,
  'parse_meridiem: a';

throws_ok { parse_meridiem('p') }
  qr/Unable to parse: meridiem is invalid/,
  'parse_meridiem: p';

throws_ok { parse_meridiem('noon') }
  qr/Unable to parse: meridiem is invalid/,
  'parse_meridiem: noon';

# parse_tz_offset

throws_ok { parse_tz_offset() }
  qr/^Usage: parse_tz_offset/,
  'parse_tz_offset: no arguments';

# ±HHMM
is(parse_tz_offset('+0000'),   0*60,    "parse_tz_offset: '+0000'");
is(parse_tz_offset('+0100'),   1*60,    "parse_tz_offset: '+0100'");
is(parse_tz_offset('+0530'),   5*60+30, "parse_tz_offset: '+0530'");
is(parse_tz_offset('+1200'),  12*60,    "parse_tz_offset: '+1200'");
is(parse_tz_offset('-0100'),  -1*60,    "parse_tz_offset: '-0100'");
is(parse_tz_offset('-0500'),  -5*60,    "parse_tz_offset: '-0500'");
is(parse_tz_offset('-0800'),  -8*60,    "parse_tz_offset: '-0800'");
is(parse_tz_offset('-1200'), -12*60,    "parse_tz_offset: '-1200'");

# ±HH:MM
is(parse_tz_offset('+00:00'),   0*60,      "parse_tz_offset: '+00:00'");
is(parse_tz_offset('+01:00'),   1*60,      "parse_tz_offset: '+01:00'");
is(parse_tz_offset('+05:30'),   5*60+30,   "parse_tz_offset: '+05:30'");
is(parse_tz_offset('+05:45'),   5*60+45,   "parse_tz_offset: '+05:45'");
is(parse_tz_offset('-05:00'),  -5*60,      "parse_tz_offset: '-05:00'");
is(parse_tz_offset('-09:30'), -(9*60+30),  "parse_tz_offset: '-09:30'");

# ±HH
is(parse_tz_offset('+00'),   0*60, "parse_tz_offset: '+00'");
is(parse_tz_offset('+01'),   1*60, "parse_tz_offset: '+01'");
is(parse_tz_offset('+09'),   9*60, "parse_tz_offset: '+09'");
is(parse_tz_offset('-05'),  -5*60, "parse_tz_offset: '-05'");
is(parse_tz_offset('-09'),  -9*60, "parse_tz_offset: '-09'");

# ±H
is(parse_tz_offset('+0'),   0*60, "parse_tz_offset: '+0'");
is(parse_tz_offset('+5'),   5*60, "parse_tz_offset: '+5'");
is(parse_tz_offset('+9'),   9*60, "parse_tz_offset: '+9'");
is(parse_tz_offset('-5'),  -5*60, "parse_tz_offset: '-5'");
is(parse_tz_offset('-9'),  -9*60, "parse_tz_offset: '-9'");

# ±H:MM
is(parse_tz_offset('+5:30'),   5*60+30,  "parse_tz_offset: '+5:30'");
is(parse_tz_offset('+5:45'),   5*60+45,  "parse_tz_offset: '+5:45'");
is(parse_tz_offset('-5:30'), -(5*60+30), "parse_tz_offset: '-5:30'");
is(parse_tz_offset('-9:30'), -(9*60+30), "parse_tz_offset: '-9:30'");

# boundary offsets
is(parse_tz_offset('+23'),     23*60,      "parse_tz_offset: '+23'");
is(parse_tz_offset('-23'),    -23*60,      "parse_tz_offset: '-23'");
is(parse_tz_offset('+23:59'),  23*60+59,   "parse_tz_offset: '+23:59'");
is(parse_tz_offset('-23:59'), -(23*60+59), "parse_tz_offset: '-23:59'");

# invalid format
throws_ok { parse_tz_offset('') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: empty string';

throws_ok { parse_tz_offset('0000') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: missing sign';

throws_ok { parse_tz_offset('Z') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: Z';

throws_ok { parse_tz_offset('UTC') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: UTC';

throws_ok { parse_tz_offset('+') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: sign only';

throws_ok { parse_tz_offset('+abc') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: non-numeric';

# out of range
throws_ok { parse_tz_offset('+24') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: hour 24';

throws_ok { parse_tz_offset('-24') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: hour -24';

throws_ok { parse_tz_offset('+00:60') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: minute 60';

throws_ok { parse_tz_offset('+2400') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: +2400';

throws_ok { parse_tz_offset('-2400') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: -2400';

throws_ok { parse_tz_offset('+0060') }
  qr/Unable to parse: timezone offset is invalid/,
  'parse_tz_offset: +0060';

done_testing();
