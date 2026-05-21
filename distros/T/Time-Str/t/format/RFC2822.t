#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

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

    # Without seconds
    [ 'Mon, 24 Dec 2012 15:30 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_offset => 60
      }
    ],

    # Without day name
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

    # Without day name, without seconds
    [ '24 Dec 2012 15:30 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_offset => 60
      }
    ],

    # Single-digit day
    [ '1 Jan 2012 00:00:00 +0000' => {
        year      => 2012,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_offset => 0
      }
    ],

    # UTC designator
    [ '24 Dec 2012 15:30:45 UT' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'UT',
        tz_offset => 0
      }
    ],

    [ '24 Dec 2012 15:30:45 UTC' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'UTC',
        tz_offset => 0
      }
    ],

    [ '24 Dec 2012 15:30:45 GMT' => {
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

    [ '1 Jan 0001 00:00:00 +0000' => {
        year      => 1,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_offset => 0
      }
    ],

    [ '31 Dec 9999 23:59:59 +0000' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 0
      }
    ],

    # Case-insensitive month and day name
    [ 'mon, 24 dec 2012 15:30:45 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    # Parenthesized comment
    [ '24 Dec 2012 15:30:45 +0100 (CET)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'RFC2822');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC2822')]);
  }
}

{
  my @tests = (
    [ '-2359', -1439 ],
    [ '-1200',  -720 ],
    [ '-0500',  -300 ],
    [ '-0100',   -60 ],
    [ '-0001',    -1 ],
    [ '+0001',     1 ],
    [ '+0100',    60 ],
    [ '+0530',   330 ],
    [ '+1400',   840 ],
    [ '+2359',  1439 ],
  );

  my $base_str = '24 Dec 2012 15:30:45 ';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
  );

  foreach my $case (@tests) {
    my ($zone, $offset) = @$case;
    my $str = $base_str . $zone;
    my $exp = {%base_exp, tz_offset => $offset};
    my $got = str2date($str, format => 'RFC2822');
    is_deeply($got, $exp, qq[str2date('$str', format => 'RFC2822')]);
  }
}

{
  my @tests = (
    [ '1 Jan 1970 00:00:00 +0000'       =>  0 ],
    [ '1 Jan 1970 01:00:00 +0100'       =>  0 ],
    [ '31 Dec 1969 19:00:00 -0500'      =>  0 ],
    [ 'Mon, 24 Dec 2012 15:30:45 +0100' =>  1356359445   ],
    [ '24 Dec 2012 14:30:45 +0000'      =>  1356359445   ],
    [ '24 Dec 2012 09:30:45 -0500'      =>  1356359445   ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'RFC2822');
    is($got, $time, qq[str2time('$string', format => 'RFC2822')]);
  }
}

{
  my @tests = (
    [ 'Mon, 24 Dec 2012 15:30:45 +0100',
      1356359445,
      { offset => 60 }
    ],
    [ 'Mon, 24 Dec 2012 09:30:45 -0500',
      1356359445,
      { offset => -300 }
    ],
    [ 'Mon, 24 Dec 2012 14:30:45 +0000',
      1356359445,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'RFC2822', %$params);
    is($got, $string, qq[time2str($time, format => 'RFC2822', $params_str)]);
  }
}

done_testing();
