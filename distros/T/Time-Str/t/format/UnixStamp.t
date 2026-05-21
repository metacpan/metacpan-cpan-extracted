#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

# Zone before year: [DDD ] MMM (_D|D|DD) hh:mm:ss ZONE YYYY
{
  my @tests = (
    [ 'Mon Dec 24 15:30:45 +0100 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ 'Thu Jan  1 00:00:00 +0000 1970' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_offset => 0
      }
    ],

    [ 'Sun Nov  6 08:49:37 -0500 1994' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_offset => -300
      }
    ],

    [ 'Mon Dec 24 15:30:45 UTC 2012' => {
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

    [ 'Sun Nov  6 08:49:37 GMT 1994' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    # Timezone abbreviation
    [ 'Mon Dec 24 15:30:45 CET 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_abbrev => 'CET'
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$string', format => 'UnixStamp')]);
  }
}

# Year before zone: [DDD ] MMM (_D|D|DD) hh:mm:ss YYYY ZONE
{
  my @tests = (
    [ 'Mon Dec 24 15:30:45 2012 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ 'Thu Jan  1 00:00:00 1970 +0000' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_offset => 0
      }
    ],

    [ 'Mon Dec 24 15:30:45 2012 UTC' => {
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

    [ 'Sun Nov  6 08:49:37 1994 GMT' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Mon Dec 24 15:30:45 2012 CET' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_abbrev => 'CET'
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$string', format => 'UnixStamp')]);
  }
}

# Year only
{
  my @tests = (
    [ 'Mon Dec 24 15:30:45 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$string', format => 'UnixStamp')]);
  }
}

# Optional day name
{
  my @tests = (
    [ 'Dec 24 15:30:45 +0100 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],
    [ 'Dec 24 15:30:45 2012 +0100' => {
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
    my $got = str2date($string, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$string', format => 'UnixStamp')]);
  }
}

# Optional seconds
{
  my @tests = (
    [ 'Mon Dec 24 15:30 +0100 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_offset => 60
      }
    ],

    [ 'Mon Dec 24 15:30 UTC 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_utc    => 'UTC',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$string', format => 'UnixStamp')]);
  }
}

# Fractional seconds
{
  my @tests = (
    [ '.123456789', 123456789 ],
    [ '.12345678',  123456780 ],
    [ '.1234567',   123456700 ],
    [ '.123456',    123456000 ],
    [ '.12345',     123450000 ],
    [ '.1234',      123400000 ],
    [ '.123',       123000000 ],
    [ '.12',        120000000 ],
    [ '.1',         100000000 ],
  );

  my $base_str = 'Mon Dec 24 15:30:45';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_offset => 60,
  );

  foreach my $case (@tests) {
    my ($fraction, $nanosecond) = @$case;
    my $str = $base_str . $fraction . ' +0100 2012';
    my $exp = {%base_exp, nanosecond => $nanosecond};
    my $got = str2date($str, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$str', format => 'UnixStamp')]);
  }
}

# Offset table
{
  my @tests = (
    [ '-2359', -1439 ],
    [ '-1200',  -720 ],
    [ '-0530',  -330 ],
    [ '-0500',  -300 ],
    [ '-0100',   -60 ],
    [ '-0001',    -1 ],
    [ '+0000',     0 ],
    [ '+0001',     1 ],
    [ '+0100',    60 ],
    [ '+0530',   330 ],
    [ '+1400',   840 ],
    [ '+2359',  1439 ],
  );

  my $base_str = 'Mon Dec 24 15:30:45';
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
    my $str = $base_str . " $zone 2012";
    my $exp = {%base_exp, tz_offset => $offset};
    my $got = str2date($str, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$str', format => 'UnixStamp')]);
  }
}

# UTC/GMT with offset
{
  my @tests = (
    [ 'Mon Dec 24 15:30:45 UTC+0100 2012' => {
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

    [ 'Mon Dec 24 15:30:45 GMT-0500 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => -300
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'UnixStamp');
    is_deeply($got, $exp, qq[str2date('$string', format => 'UnixStamp')]);
  }
}

# str2time
{
  my @tests = (
    [ 'Thu Jan  1 00:00:00 +0000 1970'   =>  0          ],
    [ 'Mon Dec 24 15:30:45 +0100 2012'   =>  1356359445 ],
    [ 'Mon Dec 24 14:30:45 UTC 2012'     =>  1356359445 ],
    [ 'Mon Dec 24 09:30:45 -0500 2012'   =>  1356359445 ],
    [ 'Mon Dec 24 14:30:45 2012 +0000'   =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'UnixStamp');
    is($got, $time, qq[str2time('$string', format => 'UnixStamp')]);
  }
}

# str2time with fractional seconds
{
  my $string = 'Mon Dec 24 14:30:45.500 UTC 2012';
  my $got = str2time($string, format => 'UnixStamp');
  delta_ok($got, 1356359445.5, qq[str2time('$string', format => 'UnixStamp')]);
}

# time2str
{
  my @tests = (
    [ 'Thu Jan  1 00:00:00 UTC 1970',
      0,
      {}
    ],

    [ 'Mon Dec 24 15:30:45 +0100 2012',
      1356359445,
      { offset => 60 }
    ],

    [ 'Mon Dec 24 09:30:45 -0500 2012',
      1356359445,
      { offset => -300 }
    ],

    [ 'Mon Dec 24 14:30:45 UTC 2012',
      1356359445,
      {}
    ],

    [ 'Sun Nov  6 08:49:37 UTC 1994',
      784111777,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'UnixStamp', %$params);
    is($got, $string, qq[time2str($time, format => 'UnixStamp', $params_str)]);
  }
}

# time2str with nanosecond
{
  my $time = 1356359445;
  {
    my $got = time2str($time, format => 'UnixStamp', nanosecond => 500_000_000);
    my $exp = 'Mon Dec 24 14:30:45.500 UTC 2012';
    is($got, $exp, 'nanosecond parameter adds fractional seconds');
  }
  {
    my $got = time2str($time, format => 'UnixStamp', nanosecond => 0);
    my $exp = 'Mon Dec 24 14:30:45 UTC 2012';
    is($got, $exp, 'nanosecond 0 produces no fraction');
  }
  {
    my $got = time2str($time, format => 'UnixStamp', nanosecond => 0, precision => 3);
    my $exp = 'Mon Dec 24 14:30:45.000 UTC 2012';
    is($got, $exp, 'nanosecond 0 with precision produces fraction');
  }
}

done_testing();
