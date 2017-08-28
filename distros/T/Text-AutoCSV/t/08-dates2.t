#!/usr/bin/perl

# t/08-dates2.t

#
# Written by Sébastien Millet
# June, July 2016
#

#
# Test script for Text::AutoCSV: dates management, part 2
#
# Text::AutoCSV uses the module 'Memoize' since version 1.2.0, to speed up this
# script execution.
# See corresponding comment in AutoCSV.pm by looking for the string 'memoize'.
#

use strict;
use warnings;

#
# Set it to 1 if indeed, as this module' author, you have en and fr (and
# nothing more) locales available on your system.
#
# Obviously, has to be unset by default...
#
my $TEST_LOCALES_ASSUMING_EN_FR_ARE_AVAILABLE;
BEGIN { $TEST_LOCALES_ASSUMING_EN_FR_ARE_AVAILABLE = 0; }

use Test::More tests =>
  ( $TEST_LOCALES_ASSUMING_EN_FR_ARE_AVAILABLE ? 44 : 31 );

#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !!( $^O =~ /mswin/i );
my $ww = ( $OS_IS_PLAIN_WINDOWS ? 'ww' : '' );

# FIXME
# If the below is zero, ignore this FIX ME entry
# If the below is non zero, it'll use some hacks to ease development
my $DEVTIME = 0;

# FIXME
# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
    use_ok('Text::AutoCSV');
}

use File::Temp qw(tmpnam);

if ($DEVTIME) {
    note("");
    note("***");
    note("***");
    note("***  !! WARNING !!");
    note("***");
    note("***  SET \$DEVTIME TO 0 BEFORE RELEASING THIS CODE TO PRODUCTION");
    note("***  RIGHT NOW, \$DEVTIME IS EQUAL TO $DEVTIME");
    note("***");
    note("***");
    note("");
}

can_ok( 'Text::AutoCSV', ('new') );

# * **** *
# * Date *
# * **** *

note("\n[SI]mple date tests");

is_deeply(
    Text::AutoCSV->new( in_file => "t/${ww}dt1.csv", fields_dates_auto => 1 )
      ->_dds(),
    {
        'A' => '%Y-%m-%d',
        'B' => '%Y.%m.%d',
        'C' => '%Y/%m/%d',
        'D' => 'N',
        'E' => 'Z',
        'F' => 'N',
        'G' => 'A',
        'H' => '%m/%d/%Y',
        'I' => '%d/%m/%Y',
        'J' => '%m.%d.%Y',
        'K' => '%d.%m.%Y',
        'L' => '%m-%d-%Y',
        'M' => '%d-%m-%Y',
        '.' => 0
    },
    "SI01 - dt1.csv: various dates formats (default formats tested)"
);

is_deeply(
    Text::AutoCSV->new(
        in_file              => "t/${ww}dt1.csv",
        fields_dates_auto    => 1,
        dates_formats_to_try => [
            '%Y-%m-%d', '%y.%m.%d', 'DD%Y%m%d', '%Y.%m.%d',
            '%d/%m/%y', '%y-%m-%d'
        ]
      )->_dds(),
    {
        'A' => '%Y-%m-%d',
        'B' => '%Y.%m.%d',
        'C' => 'N',
        'D' => 'DD%Y%m%d',
        'E' => 'Z',
        'F' => 'N',
        'G' => '%d/%m/%y',
        'H' => 'N',
        'I' => '%d/%m/%y',
        'J' => 'N',
        'K' => 'N',
        'L' => 'N',
        'M' => 'N',
        '.' => 0
    },
    "SI02 - dt1.csv: various dates formats (custom formats tested)"
);

is_deeply(
    Text::AutoCSV->new(
        in_file           => "t/${ww}dt1.csv",
        fields_dates_auto => 1,
        dates_zeros_ok    => 0
      )->_dds(),
    {
        'A' => 'N',
        'B' => '%Y.%m.%d',
        'C' => '%Y/%m/%d',
        'D' => 'N',
        'E' => 'Z',
        'F' => 'N',
        'G' => 'A',
        'H' => '%m/%d/%Y',
        'I' => '%d/%m/%Y',
        'J' => '%m.%d.%Y',
        'K' => 'N',
        'L' => '%m-%d-%Y',
        'M' => '%d-%m-%Y',
        '.' => 0
    },
"SI03 - dt1.csv: various dates formats (default formats tested + 0s disallowed)"
);

is_deeply(
    Text::AutoCSV->new(
        in_file              => "t/${ww}dt1.csv",
        fields_dates_auto    => 1,
        dates_formats_to_try => [
            '%Y-%m-%d', '%y.%m.%d', 'DD%Y%m%d', '%Y.%m.%d',
            '%d/%m/%y', '%y-%m-%d'
        ],
        dates_zeros_ok => 0
      )->_dds(),
    {
        'A' => 'N',
        'B' => '%Y.%m.%d',
        'C' => 'N',
        'D' => 'DD%Y%m%d',
        'E' => 'Z',
        'F' => 'N',
        'G' => '%d/%m/%y',
        'H' => 'N',
        'I' => '%d/%m/%y',
        'J' => 'N',
        'K' => 'N',
        'L' => 'N',
        'M' => 'N',
        '.' => 0
    },
"SI04 - dt1.csv: various dates formats (custom formats tested + 0s disallowed)"
);

# * ***************************** *
# * Time or Date followed by Time *
# * ***************************** *

note("\nMore [CO]mplex strings with date and time");

my $r =
  Text::AutoCSV->new( in_file => "t/${ww}dt2.csv", fields_dates_auto => 1 )
  ->_dds();
is_deeply(
    $r,
    {
        'A' => '%d/%m/%y',
        'B' => '%T',
        'C' => '%d/%m/%Y',
        'D' => '%R',
        'E' => '%d/%m/%y %R',
        'F' => '%d/%m/%Y %T',
        'G' => 'A',
        'H' => '%d/%m/%y %T',
        'I' => '%d/%m/%Y %R',
        '.' => 0
    },
    "CO01 - dt2.csv: date with time (24-hour format)"
);

is_deeply(
    Text::AutoCSV->new( in_file => "t/${ww}dt3.csv", fields_dates_auto => 1 )
      ->_dds(),
    {
        'A' => '%I:%M:%S %p',
        'B' => '%d/%m/%Y %I:%M:%S %p',
        'C' => '%d/%m/%Y %I:%M %p',
        'D' => '%d/%m/%y %I:%M %p',
        'E' => '%d/%m/%y %I:%M:%S%p',
        'F' => '%I:%M:%S %p',
        'G' => '%d/%m/%Y %I:%M:%S %p',
        'H' => '%d/%m/%Y %I:%M %p',
        'I' => '%d/%m/%y %I:%M%p',
        'J' => '%d/%m/%y %I:%M:%S %p',
        'K' => '%T',
        'L' => '%d/%m/%Y %T',
        'M' => '%d/%m/%Y %R',
        'N' => '%d/%m/%y %R',
        'O' => '%d/%m/%y %T',
        'P' => '%T',
        'Q' => '%d/%m/%Y %T',
        'R' => '%d/%m/%Y %R',
        'S' => '%d/%m/%y %R',
        'T' => '%d/%m/%y %T',
        '.' => 40
    },
    "CO02 - dt3.csv: date with time OK (all formats, including AM/PM format)"
);

is_deeply(
    Text::AutoCSV->new( in_file => "t/${ww}dt4.csv", fields_dates_auto => 1 )
      ->_dds(),
    {
        'A' => 'N',
        'B' => '%d/%m/%Y',
        'C' => 'N',
        'D' => '%d/%m/%y %I:%M %p',
        'E' => '%d/%m/%y %T',
        'F' => 'N',
        'G' => '%d/%m/%Y',
        'H' => 'N',
        'I' => '%d/%m/%y',
        'J' => '%d/%m/%y_%I:%M:%S %p',
        'K' => '%T',
        'L' => '%d/%m/%Y',
        'M' => '%d/%m/%Y %R',
        'N' => '%d/%m/%y %R',
        'O' => '%d/%m/%y alors ? %T',
        'P' => 'N',
        'Q' => '%d/%m/%Y%T',
        'R' => '%d/%m/%Y    %R',
        'S' => '%d/%m/%y_T_%R',
        'T' => '%d/%m/%yT%T',
        'U' => '%d/%m/%y',
        '.' => 44
    },
"CO03 - dt4.csv: date with time with errors (all formats, including AM/PM format)"
);

is_deeply(
    Text::AutoCSV->new( in_file => "t/${ww}dt5.csv", fields_dates_auto => 1 )
      ->_dds(),
    { 'A' => 'Z', 'B' => 'Z', 'C' => 'Z', '.' => 0 },
    "CO04 - dt5.csv: only a header line"
);

is_deeply(
    Text::AutoCSV->new( in_file => "t/${ww}dt6.csv", fields_dates_auto => 1 )
      ->_dds(),
    {
        'A' => '%I:%M:%S %p',
        'B' => '%I:%M:%S %p',
        'C' => '%I:%M %p',
        'D' => '%I:%M %p',
        'E' => '%I:%M:%S%p',
        'F' => '%I:%M:%S %p',
        'G' => '%I:%M:%S %p',
        'H' => '%I:%M %p',
        'I' => '%I:%M%p',
        'J' => '%I:%M:%S %p',
        'K' => '%T',
        'L' => '%T',
        'M' => '%R',
        'N' => '%R',
        'O' => '%T',
        'P' => '%T',
        'Q' => '%T',
        'R' => '%R',
        'S' => '%R',
        'T' => '%T',
        '.' => 39
    },
    "CO05 - dt6.csv: only times OK"
);

is_deeply(
    Text::AutoCSV->new( in_file => "t/${ww}dt7.csv", fields_dates_auto => 1 )
      ->_dds(),
    {
        'A' => '%I:%M:%S %p',
        'B' => '%I:%M:%S %p',
        'C' => '%I:%M %p',
        'D' => '%I:%M %p',
        'E' => '%I:%M:%S%p',
        'F' => '%I:%M:%S %p',
        'G' => '%Y.%m.%d sep %I:%M:%S %p',
        'H' => '%I:%M %p',
        'I' => 'N',
        'J' => '%I:%M:%S %p',
        'K' => 'N',
        'L' => '%T',
        'M' => '%R',
        'N' => '%R',
        'O' => 'A',
        'P' => '%T',
        'Q' => '%T',
        'R' => '%R',
        'S' => '%R',
        'T' => '%T',
        '.' => 0
    },
    "CO06 - dt7.csv: custom times without specific formats provided"
);

is_deeply(
    Text::AutoCSV->new(
        in_file              => "t/${ww}dt7.csv",
        fields_dates_auto    => 1,
        dates_formats_to_try => ['DD%Y-%m-%dTT%T']
      )->_dds(),
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => 'N',
        'K' => 'DD%Y-%m-%dTT%T',
        'L' => 'N',
        'M' => 'N',
        'N' => 'N',
        'O' => 'N',
        'P' => 'N',
        'Q' => 'N',
        'R' => 'N',
        'S' => 'N',
        'T' => 'N',
        '.' => 40
    },
    "CO07 - dt7.csv: custom times with one specific format"
);

is_deeply(
    Text::AutoCSV->new(
        in_file              => "t/${ww}dt7.csv",
        fields_dates_auto    => 1,
        dates_formats_to_try => [ '', 'DD%Y-%m-%dTT%T' ]
      )->_dds(),
    {
        'A' => '%I:%M:%S %p',
        'B' => '%I:%M:%S %p',
        'C' => '%I:%M %p',
        'D' => '%I:%M %p',
        'E' => '%I:%M:%S%p',
        'F' => '%I:%M:%S %p',
        'G' => 'N',
        'H' => '%I:%M %p',
        'I' => 'N',
        'J' => '%I:%M:%S %p',
        'K' => 'DD%Y-%m-%dTT%T',
        'L' => '%T',
        'M' => '%R',
        'N' => '%R',
        'O' => 'N',
        'P' => '%T',
        'Q' => '%T',
        'R' => '%R',
        'S' => '%R',
        'T' => '%T',
        '.' => 40
    },
"CO08 - dt7.csv: custom times with one specific format, provided empty string"
);

# * ********************** *
# * Strange custom formats *
# * ********************** *

note("\n[ST]range custom formats tests");

my $r1 = Text::AutoCSV->new(
    in_file              => "t/${ww}dt7.csv",
    fields_dates_auto    => 1,
    dates_formats_to_try => [
        '',
        'DD%Y-%m-%dTT%T',
        '%Y.%m.%d sep %I:%M:%S %p',
        'opening %I:%M%p closing',
        '%d.%m.%y ALPHA %R'
    ]
)->_dds();
is_deeply(
    $r1,
    {
        'A' => '%I:%M:%S %p',
        'B' => '%I:%M:%S %p',
        'C' => '%I:%M %p',
        'D' => '%I:%M %p',
        'E' => '%I:%M:%S%p',
        'F' => '%I:%M:%S %p',
        'G' => '%Y.%m.%d sep %I:%M:%S %p',
        'H' => '%I:%M %p',
        'I' => 'opening %I:%M%p closing',
        'J' => '%I:%M:%S %p',
        'K' => 'DD%Y-%m-%dTT%T',
        'L' => '%T',
        'M' => '%R',
        'N' => '%R',
        'O' => '%d.%m.%y ALPHA %R',
        'P' => '%T',
        'Q' => '%T',
        'R' => '%R',
        'S' => '%R',
        'T' => '%T',
        '.' => 40
    },
"ST01 - dt7.csv: custom times with all specific formats, provided empty string"
);

my $r2 = Text::AutoCSV->new(
    in_file              => "t/${ww}dt7.csv",
    fields_dates_auto    => 1,
    dates_formats_to_try => [
        'DD%Y-%m-%dTT%T',
        '%Y.%m.%d sep %I:%M:%S %p',
        'opening %I:%M%p closing',
        '%d.%m.%y ALPHA %R'
    ]
)->_dds();
is_deeply(
    $r2,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => '%Y.%m.%d sep %I:%M:%S %p',
        'H' => 'N',
        'I' => 'opening %I:%M%p closing',
        'J' => 'N',
        'K' => 'DD%Y-%m-%dTT%T',
        'L' => 'N',
        'M' => 'N',
        'N' => 'N',
        'O' => '%d.%m.%y ALPHA %R',
        'P' => 'N',
        'Q' => 'N',
        'R' => 'N',
        'S' => 'N',
        'T' => 'N',
        '.' => 40
    },
    "ST02 - dt7.csv: custom times with all specific formats"
);

# * **************************** *
# * ignore_trailing_chars option *
# * **************************** *

note("\n[IG]nore_trailing_chars option tests");

my $rt = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt8.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0
)->_dds();
is_deeply(
    $rt,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => '%R',
        'J' => '%m/%d/%Y %R',
        'K' => '%R',
        'L' => '%d/%m/%Y',
        'M' => 'N',
        '.' => 2
    },
    "IG01 - dt8.csv: ignore_trailing_chars option unset"
);

my $ru = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt8.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 1
)->_dds();
is_deeply(
    $ru,
    {
        'A' => '%d/%m/%Y %T',
        'B' => '%d/%m/%Y %I:%M:%S %p',
        'C' => '%d/%m/%Y %R',
        'D' => '%d/%m/%Y %I:%M %p',
        'E' => '%T',
        'F' => '%R',
        'G' => '%T',
        'H' => '%I:%M %p',
        'I' => '%R',
        'J' => '%m/%d/%Y %R',
        'K' => '%R',
        'L' => '%d/%m/%Y',
        'M' => 'N',
        '.' => 2
    },
    "IG02 - dt8.csv: ignore_trailing_chars option set"
);

my $rv = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt7.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0
)->_dds();
is_deeply(
    $rv,
    {
        'A' => '%I:%M:%S %p',
        'B' => 'N',
        'C' => '%I:%M %p',
        'D' => '%I:%M %p',
        'E' => '%I:%M:%S%p',
        'F' => '%I:%M:%S %p',
        'G' => '%Y.%m.%d sep %I:%M:%S %p',
        'H' => '%I:%M %p',
        'I' => 'N',
        'J' => '%I:%M:%S %p',
        'K' => 'N',
        'L' => 'N',
        'M' => '%R',
        'N' => '%R',
        'O' => 'A',
        'P' => '%T',
        'Q' => '%T',
        'R' => '%R',
        'S' => '%R',
        'T' => '%T',
        '.' => 0
    },
    "IG03 - dt7.csv: default formats, ignore_trailing_chars option unset"
);

my $rw = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt7.csv",
    fields_dates_auto           => 1,
    dates_formats_to_try        => ['DD%Y-%m-%dTT%T'],
    dates_ignore_trailing_chars => 0
)->_dds();
is_deeply(
    $rw,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => 'N',
        'K' => 'DD%Y-%m-%dTT%T',
        'L' => 'N',
        'M' => 'N',
        'N' => 'N',
        'O' => 'N',
        'P' => 'N',
        'Q' => 'N',
        'R' => 'N',
        'S' => 'N',
        'T' => 'N',
        '.' => 40
    },
    "IG04 - dt7.csv: format specified, ignore_trailing_chars option unset"
);

my $rx = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt9.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 1
)->_dds();
is_deeply(
    $rx,
    {
        'A' => '%d/%m/%y',
        'B' => '%T',
        'C' => '%d/%m/%Y',
        'D' => '%R',
        'E' => '%d/%m/%y %R',
        'F' => '%d/%m/%Yarf%T',
        'G' => 'A',
        'H' => '%d/%m/%y %T',
        'I' => '%d/%m/%Y%R',
        'J' => '%R',
        'K' => 'N',
        'L' => '%d/%m/%y',
        'M' => 'N',
        'N' => 'A',
        'O' => '%d/%m/%Y',
        'P' => '%m/%d/%Y',
        '.' => 0
    },
    "IG05 - dt9.csv: ignore_trailing_chars option set"
);

my $ry = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt9.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0
)->_dds();
is_deeply(
    $ry,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => '%d/%m/%Yarf%T',
        'G' => 'N',
        'H' => 'N',
        'I' => '%d/%m/%Y%R',
        'J' => 'N',
        'K' => 'N',
        'L' => 'N',
        'M' => 'N',
        'N' => 'A',
        'O' => '%d/%m/%Y',
        'P' => '%m/%d/%Y',
        '.' => 0
    },
    "IG06 - dt9.csv: ignore_trailing_chars option unset"
);

# * ***************** *
# * parse_time option *
# * ***************** *

note("\n[PA]rse_time option tests");

my $ss = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt8.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0,
    dates_search_time           => 0
)->_dds();
is_deeply(
    $ss,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => 'N',
        'K' => 'N',
        'L' => '%d/%m/%Y',
        'M' => 'N',
        '.' => 2
    },
    "PA01 - dt8.csv: parse_time unset, ignore_trailing_chars option unset"
);

my $st = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt8.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0,
    dates_search_time           => 1
)->_dds();
is_deeply(
    $st,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => '%R',
        'J' => '%m/%d/%Y %R',
        'K' => '%R',
        'L' => '%d/%m/%Y',
        'M' => 'N',
        '.' => 2
    },
    "PA02 - dt8.csv: parse_time set, ignore_trailing_chars option unset"
);

my $su = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt8.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 1,
    dates_search_time           => 0
)->_dds();
is_deeply(
    $su,
    {
        'A' => '%d/%m/%Y',
        'B' => '%d/%m/%Y',
        'C' => '%d/%m/%Y',
        'D' => '%d/%m/%Y',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => '%m/%d/%Y',
        'K' => 'N',
        'L' => '%d/%m/%Y',
        'M' => 'N',
        '.' => 2
    },
    "PA03 - dt8.csv: parse_time unset, ignore_trailing_chars option set"
);

my $sv = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt7.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0,
    dates_search_time           => 0
)->_dds();
is_deeply(
    $sv,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => 'N',
        'K' => 'N',
        'L' => 'N',
        'M' => 'N',
        'N' => 'N',
        'O' => 'N',
        'P' => 'N',
        'Q' => 'N',
        'R' => 'N',
        'S' => 'N',
        'T' => 'N',
        '.' => 40
    },
"PA04 - dt7.csv: parse_time unset, default formats, ignore_trailing_chars option unset"
);

my $sw = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt7.csv",
    fields_dates_auto           => 1,
    dates_formats_to_try        => ['DD%Y-%m-%dTT%T'],
    dates_ignore_trailing_chars => 0,
    dates_search_time           => 0
)->_dds();
is_deeply(
    $sw,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => 'N',
        'K' => 'DD%Y-%m-%dTT%T',
        'L' => 'N',
        'M' => 'N',
        'N' => 'N',
        'O' => 'N',
        'P' => 'N',
        'Q' => 'N',
        'R' => 'N',
        'S' => 'N',
        'T' => 'N',
        '.' => 40
    },
"PA05 - dt7.csv: parse_time unset, format specified, ignore_trailing_chars option unset"
);

my $sx = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt9.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 1,
    dates_search_time           => 0
)->_dds();
is_deeply(
    $sx,
    {
        'A' => '%d/%m/%y',
        'B' => 'N',
        'C' => '%d/%m/%Y',
        'D' => 'N',
        'E' => '%d/%m/%y',
        'F' => '%d/%m/%Y',
        'G' => 'A',
        'H' => '%d/%m/%y',
        'I' => '%d/%m/%Y',
        'J' => 'N',
        'K' => 'N',
        'L' => '%d/%m/%y',
        'M' => 'N',
        'N' => 'A',
        'O' => '%d/%m/%Y',
        'P' => '%m/%d/%Y',
        '.' => 0
    },
    "PA06 - dt9.csv: parse_time unset, ignore_trailing_chars option set"
);

my $sy = Text::AutoCSV->new(
    in_file                     => "t/${ww}dt9.csv",
    fields_dates_auto           => 1,
    dates_ignore_trailing_chars => 0,
    dates_search_time           => 0
)->_dds();
is_deeply(
    $sy,
    {
        'A' => 'N',
        'B' => 'N',
        'C' => 'N',
        'D' => 'N',
        'E' => 'N',
        'F' => 'N',
        'G' => 'N',
        'H' => 'N',
        'I' => 'N',
        'J' => 'N',
        'K' => 'N',
        'L' => 'N',
        'M' => 'N',
        'N' => 'A',
        'O' => '%d/%m/%Y',
        'P' => '%m/%d/%Y',
        '.' => 0
    },
    "PA07 - dt9.csv: parse_time unset, ignore_trailing_chars option unset"
);

# * ******** *
# * Big file *
# * ******** *

# $N x 100 => number of CSV line parsed
# Used to be "20" until 1.1.9, now is 4 to speed it up.
my $N = 4;

note("\n[BI]g file management");

my $tmpf = get_non_existent_temp_file_name();
open my $fh, ">", $tmpf or die "Unable to open $tmpf: $!"; ## no critic (InputOutput::RequireBriefOpen)
print( $fh "a,b,c,d,e\n" );
for ( 1 .. $N ) {
    for ( 1 .. 50 ) {
        print( $fh "1/1/01,1/1/01,1/1/2001 0:0,0:0,0:0:0 AM\n" );
    }
    print( $fh "1/1/01,32/1/01,13/1/2001 0:0,0:0,0:0:0\n" );
    for ( 1 .. 50 ) {
        print( $fh "1/1/01,1/1/01,1/1/2001 0:0,0:0,0:0:0 AM\n" );
    }
}
close $fh;

note( "Will parse the file '$tmpf' of " . ( $N * 100 ) . " content lines" );
my $b = Text::AutoCSV->new( in_file => $tmpf, fields_dates_auto => 1 )->_dds();
is_deeply(
    $b,
    {
        'A' => 'A',
        'B' => 'N',
        'C' => '%d/%m/%Y %R',
        'D' => '%R',
        'E' => 'N',
        '.' => 0
    },
    "BI01 - temp file of numerous lines, default formats"
);

my $c = Text::AutoCSV->new(
    in_file                     => $tmpf,
    fields_dates_auto           => 1,
    dates_formats_to_try        => ['%R'],
    dates_ignore_trailing_chars => 0
)->_dds();
is_deeply(
    $c,
    { 'A' => 'N', 'B' => 'N', 'C' => 'N', 'D' => '%R', 'E' => 'N', '.' => 1 },
    "BI02 - temp file of numerous lines, one custom format"
);

# * *************** *
# * Localized dates *
# * *************** *

note("\n[LO]calized dates management");

if ( !$TEST_LOCALES_ASSUMING_EN_FR_ARE_AVAILABLE ) {
    note("Skipped.");
}
else {
    my $l = Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        fields_dates_auto => 1
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => '%b %d, %Y, %I:%M:%S %p',
            'B' => '%b %d %T %Z %Y',
            'C' => 'N',
            'D' => 'N',
            'E' => 'A',
            'F' => '%d/%m/%y',
            'G' => '%m/%d/%y',
            '.' => 0
        },
        "LO01 - localized formats: no localization specified"
    );

    $l = Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        fields_dates_auto => 1,
        dates_locales     => 'en, fr'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => '%b %d, %Y, %I:%M:%S %p',
            'B' => '%b %d %T %Z %Y',
            'C' => '%d %b %Y a %T',
            'D' => '%d %b %Y, %T',
            'E' => 'A',
            'F' => '%d/%m/%y',
            'G' => '%m/%d/%y',
            '.' => 0
        },
        "LO02 - localized formats: en, fr"
    );

    $l = Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        fields_dates_auto => 1,
        dates_locales     => 'fr'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => 'N',
            'B' => 'N',
            'C' => '%d %b %Y a %T',
            'D' => '%d %b %Y, %T',
            'E' => 'A',
            'F' => '%d/%m/%y',
            'G' => '%m/%d/%y',
            '.' => 0
        },
        "LO03 - localized formats: fr"
    );

    $l = Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        fields_dates_auto => 1,
        dates_locales     => 'fr, en'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => '%b %d, %Y, %I:%M:%S %p',
            'B' => '%b %d %T %Z %Y',
            'C' => '%d %b %Y a %T',
            'D' => '%d %b %Y, %T',
            'E' => 'A',
            'F' => '%d/%m/%y',
            'G' => '%m/%d/%y',
            '.' => 0
        },
        "LO04 - localized formats: fr, en"
    );

    $l = Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        fields_dates_auto => 1,
        dates_locales     => 'en'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => '%b %d, %Y, %I:%M:%S %p',
            'B' => '%b %d %T %Z %Y',
            'C' => 'N',
            'D' => 'N',
            'E' => 'A',
            'F' => '%d/%m/%y',
            'G' => '%m/%d/%y',
            '.' => 0
        },
        "LO05 - localized formats: en"
    );

    $l = Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        fields_dates_auto => 1,
        dates_locales     => 'ru'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => 'N',
            'B' => 'N',
            'C' => 'N',
            'D' => 'N',
            'E' => 'A',
            'F' => '%d/%m/%y',
            'G' => '%m/%d/%y',
            '.' => 0
        },
        "LO06 - localized formats: ru"
    );

    $l = Text::AutoCSV->new(
        in_file                     => "t/${ww}dt8.csv",
        fields_dates_auto           => 1,
        dates_ignore_trailing_chars => 0,
        dates_search_time           => 0,
        dates_locales               => 'ru,de,sl,es,it,ja'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => 'N',
            'B' => 'N',
            'C' => 'N',
            'D' => 'N',
            'E' => 'N',
            'F' => 'N',
            'G' => 'N',
            'H' => 'N',
            'I' => 'N',
            'J' => 'N',
            'K' => 'N',
            'L' => '%d/%m/%Y',
            'M' => 'N',
            '.' => 2
        },
        "LO07 - PA01 with ru,de,sl,es,it,ja locales"
    );

    $l = Text::AutoCSV->new(
        in_file                     => "t/${ww}dt8.csv",
        fields_dates_auto           => 1,
        dates_ignore_trailing_chars => 0,
        dates_search_time           => 1,
        dates_locales               => 'ru,de,sl,es,it,ja'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => 'N',
            'B' => 'N',
            'C' => 'N',
            'D' => 'N',
            'E' => 'N',
            'F' => 'N',
            'G' => 'N',
            'H' => 'N',
            'I' => '%R',
            'J' => '%m/%d/%Y %R',
            'K' => '%R',
            'L' => '%d/%m/%Y',
            'M' => 'N',
            '.' => 2
        },
        "LO08 - PA02 with ru,de,sl,es,it,ja locales"
    );

    $l = Text::AutoCSV->new(
        in_file                     => "t/${ww}dt8.csv",
        fields_dates_auto           => 1,
        dates_ignore_trailing_chars => 1,
        dates_search_time           => 0,
        dates_locales               => 'ru,de,sl,es,it,ja'
    )->_dds();
    is_deeply(
        $l,
        {
            'A' => '%d/%m/%Y',
            'B' => '%d/%m/%Y',
            'C' => '%d/%m/%Y',
            'D' => '%d/%m/%Y',
            'E' => 'N',
            'F' => 'N',
            'G' => 'N',
            'H' => 'N',
            'I' => 'N',
            'J' => '%m/%d/%Y',
            'K' => 'N',
            'L' => '%d/%m/%Y',
            'M' => 'N',
            '.' => 2
        },
        "LO09 - PA03 with ru,de,sl,es,it,ja locales"
    );

    Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        out_file          => $tmpf,
        fields_dates_auto => 1,
        dates_locales     => 'en, fr',
        out_dates_format  => '%F_%T'
    )->write();
    my $rr = make_printable(
        [
            Text::AutoCSV->new( in_file => $tmpf, fields_dates_auto => 1 )
              ->get_hr_all()
        ]
    );
    is_deeply(
        $rr,
        [
            {
                'A' => 'DATETIME: 2015-04-19T00:00:00',
                'B' => 'DATETIME: 2017-06-05T09:23:12',
                'C' => 'DATETIME: 2015-04-19T00:00:00',
                'D' => 'DATETIME: 2017-06-05T09:27:01',
                'E' => '1/1/16',
                'F' => 'DATETIME: 2016-01-01T00:00:00',
                'G' => 'DATETIME: 2016-01-01T00:00:00'
            },
            {
                'A' => 'DATETIME: 2000-05-01T00:00:00',
                'B' => undef,
                'C' => 'DATETIME: 2000-05-01T00:00:00',
                'D' => undef,
                'E' => '1/1/16',
                'F' => 'DATETIME: 2016-01-13T00:00:00',
                'G' => 'DATETIME: 2016-01-13T00:00:00'
            }
        ],
        "LO10 - check out_dates_format (1)"
    );
    $rr = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
    is_deeply(
        $rr,
        [
            {
                'A' => '2015-04-19_00:00:00',
                'B' => '2017-06-05_09:23:12',
                'C' => '2015-04-19_00:00:00',
                'D' => '2017-06-05_09:27:01',
                'E' => '1/1/16',
                'F' => '2016-01-01_00:00:00',
                'G' => '2016-01-01_00:00:00'
            },
            {
                'A' => '2000-05-01_00:00:00',
                'B' => '',
                'C' => '2000-05-01_00:00:00',
                'D' => '',
                'E' => '1/1/16',
                'F' => '2016-01-13_00:00:00',
                'G' => '2016-01-13_00:00:00'
            }
        ],
        "LO11 - check out_dates_format (2)"
    );

    Text::AutoCSV->new(
        in_file           => "t/${ww}dt10.csv",
        out_file          => $tmpf,
        fields_dates_auto => 1,
        dates_locales     => 'en, fr',
        out_dates_format  => '%d %b %Y a %T',
        out_dates_locale  => 'fr'
    )->write();
    $rr = make_printable(
        [
            Text::AutoCSV->new(
                in_file           => $tmpf,
                fields_dates_auto => 1,
                dates_locales     => 'en,fr'
            )->get_hr_all()
        ]
    );
    is_deeply(
        $rr,
        [
            {
                'A' => 'DATETIME: 2015-04-19T00:00:00',
                'B' => 'DATETIME: 2017-06-05T09:23:12',
                'C' => 'DATETIME: 2015-04-19T00:00:00',
                'D' => 'DATETIME: 2017-06-05T09:27:01',
                'E' => '1/1/16',
                'F' => 'DATETIME: 2016-01-01T00:00:00',
                'G' => 'DATETIME: 2016-01-01T00:00:00'
            },
            {
                'A' => 'DATETIME: 2000-05-01T00:00:00',
                'B' => undef,
                'C' => 'DATETIME: 2000-05-01T00:00:00',
                'D' => undef,
                'E' => '1/1/16',
                'F' => 'DATETIME: 2016-01-13T00:00:00',
                'G' => 'DATETIME: 2016-01-13T00:00:00'
            }
        ],
        "LO12 - check out_dates_locales (1)"
    );
    $rr = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
    is_deeply(
        $rr,
        [
            {
                'A' => '19 avr. 2015 a 00:00:00',
                'B' => '05 juin 2017 a 09:23:12',
                'C' => '19 avr. 2015 a 00:00:00',
                'D' => '05 juin 2017 a 09:27:01',
                'E' => '1/1/16',
                'F' => '01 janv. 2016 a 00:00:00',
                'G' => '01 janv. 2016 a 00:00:00'
            },
            {
                'A' => '01 mai 2000 a 00:00:00',
                'B' => '',
                'C' => '01 mai 2000 a 00:00:00',
                'D' => '',
                'E' => '1/1/16',
                'F' => '13 janv. 2016 a 00:00:00',
                'G' => '13 janv. 2016 a 00:00:00'
            }
        ],
        "LO13 - check out_dates_locales (2)"
    );
}

unlink $tmpf if !$DEVTIME;

done_testing();

#
# Return the name of a temporary file name that is guaranteed NOT to exist.
#
# If ever it is not possible to return such a name (file exists and cannot be
# deleted), then stop execution.
sub get_non_existent_temp_file_name {
    my $tmpf = tmpnam();
    $tmpf = 'tmp0.csv' if $DEVTIME;

    unlink $tmpf if -f $tmpf;
    die
"File '$tmpf' already exists! Unable to delete it? Any way, tests aborted."
      if -f $tmpf;
    return $tmpf;
}

sub make_printable {
    my $ar = shift;

    for my $e (@$ar) {
        for ( keys %$e ) {
            my $v = $e->{$_};
            $e->{$_} = "DATETIME: $v" if ref $v eq 'DateTime';
        }
    }
    return $ar;
}

