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
    [ '24/Dec/2012:15:30:45 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ '01/Jan/1970:00:00:00 +0000' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_offset => 0
      }
    ],

    [ '06/Nov/1994:08:49:37 -0500' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_offset => -300
      }
    ],

    [ '31/Dec/9999:23:59:59 +0000' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 0
      }
    ],

    [ '24/Dec/2012:15:30:45.500 +0100' => {
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

    [ '24/Dec/2012:15:30:45.123456789 +0100' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 123_456_789,
        tz_offset  => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'CLF');
    is_deeply($got, $exp, qq[str2date('$string', format => 'CLF')]);
  }
}

{
  my @tests = (
    [ '.123456789', 123456789 ],
    [ '.123456',    123456000 ],
    [ '.123',       123000000 ],
    [ '.1',         100000000 ],
    [ '.9',         900000000 ],
    [ '.999999999', 999999999 ],
    [ '.0',                 0 ],
    [ '.000000000',         0 ],
  );

  my $base_str = '24/Dec/2012:15:30:45';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $nanosecond) = @$case;
    my $str = $base_str . $fraction . ' +0000';
    my $exp = {%base_exp, nanosecond => $nanosecond };
    my $got = str2date($str, format => 'CLF');
    is_deeply($got, $exp, qq[str2date('$str', format => 'CLF')]);
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

  my $base_str = '24/Dec/2012:15:30:45 ';
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
    my $got = str2date($str, format => 'CLF');
    is_deeply($got, $exp, qq[str2date('$str', format => 'CLF')]);
  }
}

{
  my @tests = (
    [ '01/Jan/1970:00:00:00 +0000'     =>  0 ],
    [ '01/Jan/1970:01:00:00 +0100'     =>  0 ],
    [ '31/Dec/1969:19:00:00 -0500'     =>  0 ],
    [ '24/Dec/2012:15:30:45 +0100'     =>  1356359445 ],
    [ '24/Dec/2012:14:30:45 +0000'     =>  1356359445 ],
    [ '24/Dec/2012:09:30:45 -0500'     =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'CLF');
    is($got, $time, qq[str2time('$string', format => 'CLF')]);
  }
}

{
  my @tests = (
    [ '24/Dec/2012:15:30:45.500 +0100',     3, 1e-3, 1356359445.5       ],
    [ '24/Dec/2012:15:30:45.123456 +0100',  6, 1e-6, 1356359445.123456  ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $epsilon, $time) = @$case;

    {
      my $got = time2str($time, format => 'CLF', precision => $precision, offset => 60);
      is($got, $string, qq[time2str($time, format => 'CLF', precision => $precision, offset => 60)]);
    }
    {
      my $got = str2time($string, format => 'CLF', precision => $precision);
      delta_within($got, $time, $epsilon, qq[str2time($string, format => 'CLF', precision => $precision)]);
    }
  }
}

{
  my @tests = (
    [ '24/Dec/2012:15:30:45 +0100',
      1356359445,
      { offset => 60 }
    ],
    [ '24/Dec/2012:09:30:45 -0500',
      1356359445,
      { offset => -300 }
    ],
    [ '24/Dec/2012:14:30:45 +0000',
      1356359445,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'CLF', %$params);
    is($got, $string, qq[time2str($time, format => 'CLF', $params_str)]);
  }
}

done_testing();
