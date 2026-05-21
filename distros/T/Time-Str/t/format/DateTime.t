#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

#
# Date formats — separator-delimited group
#

{
  my @tests = (
    # Y-M-D; Numeric month
    [ '2012-12-24'       => { year => 2012, month => 12, day => 24 } ],
    [ '2012-1-1'         => { year => 2012, month => 1,  day => 1  } ],
    [ '0001-01-01'       => { year => 1,    month => 1,  day => 1  } ],
    [ '9999-12-31'       => { year => 9999, month => 12, day => 31 } ],
    [ '2012/12/24'       => { year => 2012, month => 12, day => 24 } ],
    [ '2012/1/1'         => { year => 2012, month => 1,  day => 1  } ],
    [ '2012.12.24'       => { year => 2012, month => 12, day => 24 } ],
    [ '2012.1.1'         => { year => 2012, month => 1,  day => 1  } ],

    # Y-M-D; Named month
    [ '2012-Dec-24'      => { year => 2012, month => 12, day => 24 } ],
    [ '2012-December-24' => { year => 2012, month => 12, day => 24 } ],
    [ '2012/Dec/24'      => { year => 2012, month => 12, day => 24 } ],
    [ '2012.Dec.24'      => { year => 2012, month => 12, day => 24 } ],

    # D-M-Y; Textual month
    [ '24-Dec-2012'      => { year => 2012, month => 12, day => 24 } ],
    [ '24-December-2012' => { year => 2012, month => 12, day => 24 } ],
    [ '24/Dec/2012'      => { year => 2012, month => 12, day => 24 } ],
    [ '24.Dec.2012'      => { year => 2012, month => 12, day => 24 } ],
    [ '24-XII-2012'      => { year => 2012, month => 12, day => 24 } ],
    [ '24.I.2012'        => { year => 2012, month => 1,  day => 24 } ],
    [ '1-IV-2012'        => { year => 2012, month => 4,  day => 1  } ],

    # M-D-Y; Named month
    [ 'Dec/24/2012'      => { year => 2012, month => 12, day => 24 } ],
    [ 'December-24-2012' => { year => 2012, month => 12, day => 24 } ],
    [ 'Jan.1.2012'       => { year => 2012, month => 1,  day => 1  } ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Date formats — space-delimited group
#

{
  my @tests = (
    # DD MonthTextual YYYY
    [ '24 December 2012'   => { year => 2012, month => 12, day => 24 } ],
    [ '24 Dec 2012'        => { year => 2012, month => 12, day => 24 } ],
    [ '1 Jan 2012'         => { year => 2012, month => 1,  day => 1  } ],

    # Ordinal suffixes
    [ '1st January 2012'   => { year => 2012, month => 1,  day => 1  } ],
    [ '2nd February 2012'  => { year => 2012, month => 2,  day => 2  } ],
    [ '3rd March 2012'     => { year => 2012, month => 3,  day => 3  } ],
    [ '24th December 2012' => { year => 2012, month => 12, day => 24 } ],

    # Day with trailing dot
    [ '24. December 2012'  => { year => 2012, month => 12, day => 24 } ],

    # Month with trailing comma or dot
    [ '24 December, 2012'  => { year => 2012, month => 12, day => 24 } ],
    [ '24 Dec. 2012'       => { year => 2012, month => 12, day => 24 } ],

    # Roman numeral month
    [ '24 XII 2012'        => { year => 2012, month => 12, day => 24 } ],
    [ '24. XII. 2012'      => { year => 2012, month => 12, day => 24 } ],
    [ '24 I 2012'          => { year => 2012, month => 1,  day => 24 } ],
    [ '24 VIII 2012'       => { year => 2012, month => 8,  day => 24 } ],

    # MonthName DD[,] YYYY (M D Y order)
    [ 'December 24 2012'    => { year => 2012, month => 12, day => 24 } ],
    [ 'Dec 24 2012'         => { year => 2012, month => 12, day => 24 } ],
    [ 'December 24, 2012'   => { year => 2012, month => 12, day => 24 } ],
    [ 'Dec 24, 2012'        => { year => 2012, month => 12, day => 24 } ],
    [ 'December 24th 2012'  => { year => 2012, month => 12, day => 24 } ],
    [ 'December 24th, 2012' => { year => 2012, month => 12, day => 24 } ],
    [ 'January 1st 2012'    => { year => 2012, month => 1,  day => 1  } ],
    [ 'December, 24 2012'   => { year => 2012, month => 12, day => 24 } ],
    [ 'Dec. 24 2012'        => { year => 2012, month => 12, day => 24 } ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Date formats — no-separator group
#

{
  my @tests = (
    # YYYYMonthNameDD
    [ '2012Dec24'     => { year => 2012, month => 12, day => 24 } ],
    [ '2012January1'  => { year => 2012, month => 1,  day => 1  } ],

    # DDMonthTextualYYYY
    [ '24Dec2012'     => { year => 2012, month => 12, day => 24 } ],
    [ '24DEC2012'     => { year => 2012, month => 12, day => 24 } ],
    [ '1Jan2012'      => { year => 2012, month => 1,  day => 1  } ],

    # Roman numeral month
    [ '24XII2012'     => { year => 2012, month => 12, day => 24 } ],
    [ '1I2012'        => { year => 2012, month => 1,  day => 1  } ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Day name prefix
#

{
  my @tests = (
    [ 'Mon, 24 Dec 2012'         => { year => 2012, month => 12, day => 24 } ],
    [ 'Mon 24 Dec 2012'          => { year => 2012, month => 12, day => 24 } ],
    [ 'Mon. 24 Dec 2012'         => { year => 2012, month => 12, day => 24 } ],
    [ 'Monday, 24 December 2012' => { year => 2012, month => 12, day => 24 } ],
    [ 'Monday 24 December 2012'  => { year => 2012, month => 12, day => 24 } ],

    # Tues and Thurs abbreviations
    [ 'Tues, 25 Dec 2012'        => { year => 2012, month => 12, day => 25 } ],
    [ 'Thurs, 27 Dec 2012'       => { year => 2012, month => 12, day => 27 } ],

    # Sept abbreviation
    [ 'Mon, 24 Sept 2012'        => { year => 2012, month => 9,  day => 24 } ],

    # Case-insensitive
    [ 'mon, 24 dec 2012'         => { year => 2012, month => 12, day => 24 } ],
    [ 'MONDAY, 24 DECEMBER 2012' => { year => 2012, month => 12, day => 24 } ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# All twelve months — short, long, and roman numeral
#

{
  my @months_short = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @months_long  = qw(January February March April May June
                         July August September October November December);
  my @months_roman = qw(I II III IV V VI VII VIII IX X XI XII);

  for my $m (1 .. 12) {
    {
      my $str = sprintf '24 %s 2012', $months_short[$m-1];
      my $got = str2date($str, format => 'DateTime');
      is($got->{month}, $m, qq['$str': month]);
    }
    {
      my $str = sprintf '24 %s 2012', $months_long[$m-1];
      my $got = str2date($str, format => 'DateTime');
      is($got->{month}, $m, qq['$str': month]);
    }
    {
      my $str = sprintf '24 %s 2012', $months_roman[$m-1];
      my $got = str2date($str, format => 'DateTime');
      is($got->{month}, $m, qq['$str': month]);
    }
  }
}

#
# Time — separators between date and time
#

{
  my %base_exp = (
    year   => 2012,
    month  => 12,
    day    => 24,
    hour   => 15,
    minute => 30,
  );

  my @tests = (
    # T separator
    [ '2012-12-24T15:30' => { %base_exp } ],

    # t separator (lowercase)
    [ '2012-12-24t15:30' => { %base_exp } ],

    # Space separator
    [ '2012-12-24 15:30' => { %base_exp } ],

    # Space + "at" separator
    [ '24 Dec 2012 at 15:30' => { %base_exp } ],

    # Space + "At" separator
    [ '24 Dec 2012 At 15:30' => { %base_exp } ],

    # Comma + space separator
    [ '24 Dec 2012, 15:30' => { %base_exp } ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Time — HH:MM, HH:MM:SS, HH:MM:SS.fraction
#

{
  my @tests = (
    # HH:MM
    [ '2012-12-24T15:30' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30
      }
    ],

    # HH:MM:SS
    [ '2012-12-24T15:30:45' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30,
        second => 45
      }
    ],

    # HH:MM:SS.fraction (dot)
    [ '2012-12-24T15:30:45.500Z' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_utc     => 'Z',
        tz_offset  => 0
      }
    ],

    # HH:MM:SS,fraction (comma)
    [ '2012-12-24T15:30:45,500Z' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_utc     => 'Z',
        tz_offset  => 0
      }
    ],

    # 9-digit fractional second
    [ '2012-12-24T15:30:45.123456789Z' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 123_456_789,
        tz_utc     => 'Z',
        tz_offset  => 0
      }
    ],

    # 1-digit fractional second
    [ '2012-12-24T15:30:45.5Z' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_utc     => 'Z',
        tz_offset  => 0
      }
    ],

    # Single-digit hour
    [ 'Dec/24/2012 3:30:45' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 3,
        minute => 30,
        second => 45
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Time — AM/PM (meridiem) handling
#

{
  my @tests = (
    # HH:MM:SS with meridiem
    [ 'Dec/24/2012 12:30:45 AM' =>  0, '12 AM => 0'  ],
    [ 'Dec/24/2012 12:30:45 PM' => 12, '12 PM => 12' ],
    [ 'Dec/24/2012 01:30:45 AM' =>  1, '1 AM => 1'   ],
    [ 'Dec/24/2012 01:30:45 PM' => 13, '1 PM => 13'  ],
    [ 'Dec/24/2012 11:30:45 AM' => 11, '11 AM => 11' ],
    [ 'Dec/24/2012 11:30:45 PM' => 23, '11 PM => 23' ],

    # a.m. / p.m. forms
    [ 'Dec/24/2012 03:30:45 a.m.' =>  3, 'a.m. => 3'  ],
    [ 'Dec/24/2012 03:30:45 p.m.' => 15, 'p.m. => 15' ],

    # No space before meridiem
    [ 'Dec/24/2012 03:30:45PM' => 15, 'no space before PM' ],

    # Hour-only with meridiem (no minutes)
    [ '24 Dec 2012 3 PM'  => 15, 'hour-only 3 PM'  ],
    [ '24 Dec 2012 12 AM' =>  0, 'hour-only 12 AM' ],
    [ '24 Dec 2012 12 PM' => 12, 'hour-only 12 PM' ],
    [ '24 Dec 2012 12PM'  => 12, 'hour-only 12PM no space' ],

    # Case variations
    [ 'Dec/24/2012 03:30:45 am' =>  3, 'lowercase am' ],
    [ 'Dec/24/2012 03:30:45 Pm' => 15, 'mixed case Pm' ],
    [ 'Dec/24/2012 03:30:45 A.M.' =>  3, 'uppercase A.M.' ],
    [ 'Dec/24/2012 03:30:45 P.M.' => 15, 'uppercase P.M.' ],
  );

  foreach my $case (@tests) {
    my ($string, $exp_hour, $label) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is($got->{hour}, $exp_hour, "meridiem: $label");
  }
}

#
# Timezone — numeric offsets (various formats)
#

{
  my @tests = (
    # ±HHMM
    [ '+0100',  60 ],
    [ '-0500', -300 ],
    [ '+0000',   0 ],
    [ '+0530', 330 ],
    [ '-2359', -1439 ],
    [ '+2359', 1439 ],

    # ±HH:MM
    [ '+01:00',  60 ],
    [ '-05:00', -300 ],
    [ '+00:00',   0 ],
    [ '+05:30', 330 ],

    # ±HH
    [ '+01',  60 ],
    [ '-05', -300 ],
    [ '+00',   0 ],
    [ '+14', 840 ],
  );

  my $base_str = '2012-12-24T15:30:45';
  my %base_exp = (
    year   => 2012,
    month  => 12,
    day    => 24,
    hour   => 15,
    minute => 30,
    second => 45,
  );

  foreach my $case (@tests) {
    my ($zone, $offset) = @$case;
    my $str = $base_str . $zone;
    my $exp = {%base_exp, tz_offset => $offset};
    my $got = str2date($str, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$str', format => 'DateTime')]);
  }
}

#
# Timezone — UTC designators
#

{
  my $base_str = '2012-12-24T15:30:45';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_offset => 0,
  );

  my @tests = (
    [ 'Z',   'Z'   ],
    [ 'z',   'z'   ],
    [ 'GMT', 'GMT' ],
    [ 'UTC', 'UTC' ],
  );

  foreach my $case (@tests) {
    my ($zone, $utc_val) = @$case;
    my $str = $base_str . $zone;
    my $exp = {%base_exp, tz_utc => $utc_val};
    my $got = str2date($str, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$str', format => 'DateTime')]);
  }
}

#
# Timezone — GMT/UTC with offset
#

{
  my @tests = (
    [ '2012-12-24T15:30:45 GMT+1' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 60
      }
    ],

    [ '2012-12-24T15:30:45 UTC+01:00' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'UTC',
        tz_offset => 60
      }
    ],

    [ '2012-12-24T15:30:45 GMT+0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 60
      }
    ],

    [ '2012-12-24T15:30:45 UTC-5' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'UTC',
        tz_offset => -300
      }
    ],

    # GMT/UTC without offset => offset 0
    [ '2012-12-24T15:30:45 GMT' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Timezone — abbreviation
#

{
  my @tests = (
    [ '24 Dec 2012 15:30:45 CET' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_abbrev => 'CET'
      }
    ],

    [ '24 Dec 2012 15:30:45 CEST' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_abbrev => 'CEST'
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Timezone — annotation (RFC 9557)
#

{
  my @tests = (
    [ '2012-12-24T15:30:45.500+01:00[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        nanosecond    => 500_000_000,
        tz_offset     => 60,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # Multiple annotation tags
    [ '2012-12-24T15:30:45+01:00[Europe/Stockholm][u-ca=gregory]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_offset     => 60,
        tz_annotation => '[Europe/Stockholm][u-ca=gregory]'
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Timezone — parenthesized comment
#

{
  my @tests = (
    [ '2012-12-24T15:30:45 +0100 (CET)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ 'Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[str2date('$string', format => 'DateTime')]);
  }
}

#
# Combined real-world formats from the module comment block
#

# ISO 8601
{
  my @tests = (
    [ '2012-12-24T15:30' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30
      }
    ],

    [ '2012-12-24T15:30+01' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_offset => 60
      }
    ],

    [ '2012-12-24T15:30:45,500+01' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_offset  => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[ISO 8601: '$string']);
  }
}

# RFC 3339
{
  my @tests = (
    [ '2012-12-24T15:30:45+01:00' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ '2012-12-24T15:30:45.500+01:00' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_offset  => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[RFC 3339: '$string']);
  }
}

# RFC 9557
{
  my $got = str2date('2012-12-24T15:30:45.500+01:00[Europe/Stockholm]', format => 'DateTime');
  is_deeply($got, {
    year          => 2012,
    month         => 12,
    day           => 24,
    hour          => 15,
    minute        => 30,
    second        => 45,
    nanosecond    => 500_000_000,
    tz_offset     => 60,
    tz_annotation => '[Europe/Stockholm]'
  }, q[RFC 9557: '2012-12-24T15:30:45.500+01:00[Europe/Stockholm]']);
}

# RFC 2822
{
  my @tests = (
    [ 'Mon, 24 Dec 2012 15:30:45 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ 'Mon, 24 Dec 2012 15:30 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_offset => 60
      }
    ],

    [ '24 Dec 2012 15:30:45 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ '24 Dec 2012 15:30 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_offset => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[RFC 2822: '$string']);
  }
}

# RFC 2616 (HTTP-date)
{
  my $got = str2date('Mon, 24 Dec 2012 15:30:45 GMT', format => 'DateTime');
  is_deeply($got, {
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_utc    => 'GMT',
    tz_offset => 0
  }, q[HTTP-date: 'Mon, 24 Dec 2012 15:30:45 GMT']);
}

# RFC 9051 (IMAP)
{
  my $got = str2date('24-Dec-2012 15:30:45 +0100', format => 'DateTime');
  is_deeply($got, {
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_offset => 60
  }, q[IMAP: '24-Dec-2012 15:30:45 +0100']);
}

# ISO 9075 (SQL)
{
  my @tests = (
    [ '2012-12-24 15:30:45' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30,
        second => 45
      }
    ],

    [ '2012-12-24 15:30:45 +01:00' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ '2012-12-24 15:30:45.500' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000
      }
    ],

    [ '2012-12-24 15:30:45.500 +01:00' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_offset  => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[SQL: '$string']);
  }
}

# ECMAScript Date.prototype.toString
{
  my $got = str2date('Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)', format => 'DateTime');
  is_deeply($got, {
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_utc    => 'GMT',
    tz_offset => 60
  }, q[ECMAScript: 'Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)']);
}

# Long-form textual
{
  my @tests = (
    [ 'Monday, 24 December 2012, 15:30 GMT+1' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_utc    => 'GMT',
        tz_offset => 60
      }
    ],

    [ 'Monday, 24th December 2012 at 3:30 pm UTC+1 (CET)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_utc    => 'UTC',
        tz_offset => 60
      }
    ],

    [ 'Monday, December 24, 2012, 3:30 PM' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30
      }
    ],

    [ 'December 24th, 2012 at 3:30 PM' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[long-form: '$string']);
  }
}

# Short-form variations
{
  my @tests = (
    [ 'Dec/24/2012 03:30:45 PM' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30,
        second => 45
      }
    ],

    [ '24. XII. 2012 12PM UTC+1 (CET)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 12,
        tz_utc    => 'UTC',
        tz_offset => 60
      }
    ],

    [ '24DEC2012 12:30:45.500 UTC+1' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 12,
        minute     => 30,
        second     => 45,
        nanosecond => 500_000_000,
        tz_utc     => 'UTC',
        tz_offset  => 60
      }
    ],

    [ '24.Dec.2012 15:30:45' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30,
        second => 45
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'DateTime');
    is_deeply($got, $exp, qq[short-form: '$string']);
  }
}

#
# Date validation
#

{
  # Leap year
  my $got = str2date('2012-02-29', format => 'DateTime');
  is($got->{day}, 29, 'leap year 2012-02-29');
}

{
  # Century leap year
  my $got = str2date('2000-02-29', format => 'DateTime');
  is($got->{day}, 29, 'century leap year 2000-02-29');
}

{
  eval { str2date('2012-02-30', format => 'DateTime') };
  like($@, qr/out of range/, '2012-02-30 rejected');
}

{
  eval { str2date('2012-13-01', format => 'DateTime') };
  like($@, qr/Unable to parse: month is invalid/, 'month 13 rejected');
}

{
  eval { str2date('2012-00-01', format => 'DateTime') };
  like($@, qr/Unable to parse: month is invalid/, 'month 0 rejected');
}

#
# Time validation
#

{
  eval { str2date('2012-12-24T24:00:00Z', format => 'DateTime') };
  like($@, qr/out of range/, 'hour 24 rejected');
}

{
  eval { str2date('2012-12-24T12:60:00Z', format => 'DateTime') };
  like($@, qr/out of range/, 'minute 60 rejected');
}

{
  # Leap second allowed
  my $got = str2date('2012-12-24T23:59:60Z', format => 'DateTime');
  is($got->{second}, 60, 'leap second 60 allowed');
}

{
  eval { str2date('2012-12-24T23:59:61Z', format => 'DateTime') };
  like($@, qr/out of range/, 'second 61 rejected');
}

#
# str2time via generic
#

{
  my @tests = (
    [ '2012-12-24T15:30:45+01:00'     =>  1356359445 ],
    [ '2012-12-24T14:30:45Z'          =>  1356359445 ],
    [ '1970-01-01T00:00:00Z'          =>  0          ],
    [ 'Mon, 24 Dec 2012 15:30:45 GMT' =>  1356363045 ],
    [ '24DEC2012 14:30:45 UTC'        =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'DateTime');
    is($got, $time, qq[str2time('$string', format => 'DateTime')]);
  }
}

#
# str2time requires timezone
#

{
  eval { str2time('2012-12-24T15:30:45', format => 'DateTime') };
  like($@, qr/timestamp string without a UTC designator or numeric offset/, 'str2time croaks without timezone');
}

done_testing();
