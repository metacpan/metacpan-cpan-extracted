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
    [ '00010101000000Z' => {
        year      => 1,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    [ '99991231235959Z' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    [ '99991231235959+0000' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 0
      }
    ],

    [ '99991231235959+0100' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 60
      }
    ],

    # hhmmss
    [ '20121224153045Z' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    # hhmmss,fff
    [ '20121224153045,500Z' => {
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

    # hhmmss,fffffffff
    [ '20121224153045,123456789Z' => {
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

    # hhmm
    [ '201212241530Z' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    # hhmm,f
    [ '201212241530,5Z' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 30,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    # hh
    [ '2012122415Z' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    # hh,f
    [ '2012122415,5Z' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ASN1GT');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ASN1GT')]);
  }
}

{
  my @tests = (
    [ '.0Z',          { minute => 0 } ],
    [ '.1Z',          { minute => 6 } ],
    [ '.01Z',         { minute => 0, second => 36 } ],
    [ '.001Z',        { minute => 0, second =>  3, nanosecond => 600000000 } ],
    [ '.25Z',         { minute => 15 } ],
    [ '.50Z',         { minute => 30 } ],
    [ '.75Z',         { minute => 45 } ],
    [ '30.25Z',       { minute => 30, second => 15 } ],
    [ '30.50Z',       { minute => 30, second => 30 } ],
    [ '30.75Z',       { minute => 30, second => 45 } ],
    [ '30.2525Z',     { minute => 30, second => 15, nanosecond => 150000000 } ],
    [ '30.5050Z',     { minute => 30, second => 30, nanosecond => 300000000 } ],
    [ '30.7575Z',     { minute => 30, second => 45, nanosecond => 450000000 } ],
    [ '30.0001Z',     { minute => 30, second =>  0, nanosecond =>   6000000 } ],
    [ '30.9999Z',     { minute => 30, second => 59, nanosecond => 994000000 } ],
    [ '59.999999999Z',{ minute => 59, second => 59, nanosecond => 999999940 } ],
  );

  my $base_str = '2012122415';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    tz_utc    => 'Z',
    tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $time_exp) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, %$time_exp};
    my $got = str2date($str, format => 'ASN1GT');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ASN1GT')]);
  }
}

{
  my @tests = (
    [ '.123456789Z', 123456789 ],
    [ '.12345678Z',  123456780 ],
    [ '.1234567Z',   123456700 ],
    [ '.123456Z',    123456000 ],
    [ '.12345Z',     123450000 ] ,
    [ '.1234Z',      123400000 ],
    [ '.123Z',       123000000 ],
    [ '.12Z',        120000000 ],
    [ '.1Z',         100000000 ],
    [ '.01Z',         10000000 ],
    [ '.001Z',         1000000 ],
    [ '.0001Z',         100000 ],
    [ '.00001Z',         10000 ],
    [ '.000001Z',         1000 ],
    [ '.0000001Z',         100 ],
    [ '.00000001Z',         10 ],
    [ '.000000001Z',         1 ],
    [ '.000000009Z',         9 ],
    [ '.00000009Z',         90 ],
    [ '.0000009Z',         900 ],
    [ '.000009Z',         9000 ],
    [ '.00009Z',         90000 ],
    [ '.0009Z',         900000 ],
    [ '.009Z',         9000000 ],
    [ '.09Z',         90000000 ],
    [ '.9Z',         900000000 ],
    [ '.99Z',        990000000 ],
    [ '.999Z',       999000000 ],
    [ '.9999Z',      999900000 ],
    [ '.99999Z',     999990000 ],
    [ '.999999Z',    999999000 ],
    [ '.9999999Z',   999999900 ],
    [ '.99999999Z',  999999990 ],
    [ '.999999999Z', 999999999 ],
    [ '.0Z',                 0 ],
    [ '.00Z',                0 ],
    [ '.000Z',               0 ],
    [ '.0000Z',              0 ],
    [ '.00000Z',             0 ],
    [ '.000000Z',            0 ],
    [ '.0000000Z',           0 ],
    [ '.00000000Z',          0 ],
    [ '.000000000Z',         0 ],
  );

  my $base_str = '20121224153045';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_offset => 0,
    tz_utc    => 'Z'
  );

  foreach my $case (@tests) {
    my ($fraction, $nanosecond) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, nanosecond => $nanosecond};
    my $got = str2date($str, format => 'ASN1GT');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ASN1GT')]);
  }
}

{
  my @tests = (
    [ '-2359', -1439 ],
    [ '-1200',  -720 ],
    [ '-12',    -720 ],
    [ '-0530',  -330 ],
    [ '-0500',  -300 ],
    [ '-05',    -300 ],
    [ '-0100',   -60 ],
    [ '-01',     -60 ],
    [ '-0001',    -1 ],
    [ '+0001',     1 ],
    [ '+0100',    60 ],
    [ '+01',      60 ],
    [ '+0530',   330 ],
    [ '+1400',   840 ],
    [ '+14',     840 ],
    [ '+2359',  1439 ],
  );

  my $base_str = '20121224153045';
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
    my $got = str2date($str, format => 'ASN1GT');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ASN1GT')]);
  }
}

{
  my @tests = (
    [ '00010101000000Z',      => -62135596800 ],
    [ '19700101000000Z'       =>  0 ],
    [ '19700101010000+0100'   =>  0 ],
    [ '19691231190000-0500'   =>  0 ],
    [ '20121224153045+0100'   =>  1356359445   ],
    [ '20121224143045Z'       =>  1356359445   ],
    [ '20121224093045-0500'   =>  1356359445   ],
    [ '99991231235959Z'       =>  253402300799 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'ASN1GT');
    is($got, $time, qq[str2time($string, format => 'ASN1GT')]);
  }
}

{
  my @tests = (
    [ '00010101000000.500Z',    3, 1e-3, -62135596799.5       ],
    [ '20121224153045.500Z',    3, 1e-3,  1356363045.5        ],
    [ '20121224153045.123456Z', 6, 1e-6,  1356363045.123456   ],
    [ '20121224153045.555555Z', 6, 1e-6,  1356363045.555555   ],
    [ '20121224153045.999999Z', 6, 1e-6,  1356363045.999999   ],
    [ '99991231235959.500Z',    3, 1e-3,  253402300799.5      ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $epsilon, $time) = @$case;

    {
      my $got = time2str($time, format => 'ASN1GT', precision => $precision);
      is($got, $string, qq[time2str($time, format => 'ASN1GT', precision => $precision)]);
    }
    {
      my $got = str2time($string, format => 'ASN1GT', precision => $precision);
      delta_within($got, $time, $epsilon, qq[str2time($string, format => 'ASN1GT', precision => $precision)]);
    }
  }
}

{
  my @tests = (
    [ '19700101000000.123456789Z', 9, 0.123456789 ],
    [ '19700101000000.123456789Z', 6, 0.123456    ],
    [ '19700101000000.123456789Z', 3, 0.123       ],
    [ '19700101000000.555555555Z', 3, 0.555       ],
    [ '19700101000000.555555555Z', 1, 0.5         ],
    [ '19700101000000.999999999Z', 9, 0.999999999 ],
    [ '19700101000000.999999999Z', 6, 0.999999    ],
    [ '19700101000000.999999999Z', 3, 0.999       ],
    [ '19700101000000.999999999Z', 0, 0           ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $time) = @$case;

    my $got = str2time($string, format => 'ASN1GT', precision => $precision);
    delta_within($got, $time, 1e-9, qq[str2time($string, format => 'ASN1GT', precision => $precision)]);
  }
}

{
  my $time = 1356363045.999999;
  {
    my $got = time2str($time, format => 'ASN1GT', nanosecond => 500_000_000);
    my $exp = '20121224153045.500Z';
    is($got, $exp, 'nanosecond parameter overrides fractional time');
  }
  {
    my $got = time2str($time, format => 'ASN1GT', nanosecond => 0);
    my $exp = '20121224153045Z';
    is($got, $exp, 'nanosecond parameter overrides fractional time');
  }
  {
    my $got = time2str($time, format => 'ASN1GT', nanosecond => 0, precision => 3);
    my $exp = '20121224153045.000Z';
    is($got, $exp, 'nanosecond parameter overrides fractional time');
  }
}

done_testing();
