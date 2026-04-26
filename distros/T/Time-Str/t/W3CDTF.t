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
    [ '0001'       => { year => 1 } ],
    [ '0001-01'    => { year => 1, month => 1 } ],
    [ '0001-01-01' => { year => 1, month => 1, day => 1 } ],

    [ '9999'       => { year => 9999 } ],
    [ '9999-12'    => { year => 9999, month => 12 } ],
    [ '9999-12-31' => { year => 9999, month => 12, day => 31 } ],

    [ '1900-02'    => { year => 1900, month => 2 } ],
    [ '2000-02-29' => { year => 2000, month => 2, day => 29 } ],

    [ '2012-01-31' => { year => 2012, month => 1, day => 31 } ],
    [ '2012-04-30' => { year => 2012, month => 4, day => 30 } ],
    [ '2012-02-29' => { year => 2012, month => 2, day => 29 } ],

    [ '0001-01-01T00:00:00Z' => {
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

    [ '9999-12-31T23:59:59Z' => {
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

    [ '9999-12-31T23:59:59+00:00' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 0
      }
    ],

    [ '9999-12-31T23:59:59+01:00' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 60
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'W3CDTF');
    is_deeply($got, $exp, qq[str2date('$string', format => 'W3CDTF')]);
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
  my $base_str = '2012-12-24T15:30:45';
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
    my $exp = {%base_exp, nanosecond => $nanosecond };
    my $got = str2date($str, format => 'W3CDTF');
    is_deeply($got, $exp, qq[str2date('$str', format => 'W3CDTF')]);
  }
}

{
  my @tests = (
    [ '-23:59', -1439 ],
    [ '-12:00',  -720 ],
    [ '-05:00',  -300 ],
    [ '-01:00',   -60 ],
    [ '-00:01',    -1 ],
    [ '+00:01',     1 ],
    [ '+01:00',    60 ],
    [ '+05:30',   330 ],
    [ '+14:00',   840 ],
    [ '+23:59',  1439 ],
  );

  my $base_str = '2012-12-24T15:30:45';
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
    my $got = str2date($str, format => 'W3CDTF');
    is_deeply($got, $exp, qq[str2date('$str', format => 'W3CDTF')]);
  }
}

{
  my @tests = (
    [ '0001-01-01T00:00:00Z',      => -62135596800 ],
    [ '1970-01-01T00:00:00Z'       =>  0 ],
    [ '1970-01-01T01:00:00+01:00'  =>  0 ],
    [ '1969-12-31T19:00:00-05:00'  =>  0 ],
    [ '2012-12-24T15:30:45+01:00'  =>  1356359445   ],
    [ '2012-12-24T14:30:45Z'       =>  1356359445   ],
    [ '2012-12-24T09:30:45-05:00'  =>  1356359445   ],
    [ '9999-12-31T23:59:59Z'       =>  253402300799 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'W3CDTF');
    is($got, $time, qq[str2time($string, format => 'W3CDTF')]);
  }
}

{
  my @tests = (
    [ '0001-01-01T00:00:00.500Z',    3, 1e-3, -62135596799.5       ],
    [ '2012-12-24T15:30:45.500Z',    3, 1e-3,  1356363045.5        ],
    [ '2012-12-24T15:30:45.123456Z', 6, 1e-6,  1356363045.123456   ],
    [ '2012-12-24T15:30:45.555555Z', 6, 1e-6,  1356363045.555555   ],
    [ '2012-12-24T15:30:45.999999Z', 6, 1e-6,  1356363045.999999   ],
    [ '9999-12-31T23:59:59.500Z',    3, 1e-3,  253402300799.5      ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $epsilon, $time) = @$case;

    {
      my $got = time2str($time, format => 'W3CDTF', precision => $precision);
      is($got, $string, qq[time2str($time, format => 'W3CDTF', precision => $precision)]);
    }
    {
      my $got = str2time($string, format => 'W3CDTF', precision => $precision);
      delta_within($got, $time, $epsilon, qq[str2time($string, format => 'W3CDTF', precision => $precision)]);
    }
  }
}

{
  my @tests = (
    [ '2012-12-24T15:30:45+01:00', 
      1356359445, 
      { offset => 60 } 
    ],
    [ '2012-12-24T09:30:45-05:00', 
      1356359445, 
      { offset => -300 } 
    ],
    [ '2012-12-24T20:00:45.123456+05:30', 
      1356359445, 
      { precision => 6, nanosecond => 123_456_000, offset => 330 } 
    ],
    [ '2012-12-24T15:30:45.500Z', 
      1356363045, 
      { precision => 3, nanosecond => 500_000_000 } 
    ],
    [ '2012-12-24T15:30:45Z', 
      1356363045, 
      { precision => 0, nanosecond => 999_999_999 } 
    ],
    [ '2012-12-24T15:30:45.500Z', 
      1356363045.999999, 
      { precision => 3, nanosecond => 500_000_000 } 
    ],
    [ '2012-12-24T15:30:45Z', 
      1356363045.999999, 
      { nanosecond => 0 } 
    ],
    # Rounds up to a full second
    [ '2012-12-24T15:30:46Z', 
      1356363045.999999, 
      { precision => 0 } 
    ],
    # Rounds up to a full second
    [ '2012-12-24T15:30:46.000Z', 
      1356363045.999999, 
      { precision => 3 } 
    ],
    # Does NOT round up, precision is high enough
    [ '2012-12-24T15:30:45.999999Z', 
      1356363045.999999, 
      { precision => 6 } 
    ]
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;
    
    my $params_str = join ', ', map { 
        sprintf '%s => %d', $_, $params->{$_} 
    } keys %$params;

    my $got = time2str($time, format => 'W3CDTF', %$params);
    is($got, $string, qq[time2str($time, $params_str)]);
  }
}

{
  my @tests = (
    [ '1970-01-01T00:00:00.123456789Z', 9, 0.123456789 ],
    [ '1970-01-01T00:00:00.123456789Z', 6, 0.123456    ],
    [ '1970-01-01T00:00:00.123456789Z', 3, 0.123       ],
    [ '1970-01-01T00:00:00.555555555Z', 3, 0.555       ],
    [ '1970-01-01T00:00:00.555555555Z', 1, 0.5         ],
    [ '1970-01-01T00:00:00.999999999Z', 9, 0.999999999 ],
    [ '1970-01-01T00:00:00.999999999Z', 6, 0.999999    ],
    [ '1970-01-01T00:00:00.999999999Z', 3, 0.999       ],
    [ '1970-01-01T00:00:00.999999999Z', 0, 0           ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $time) = @$case;

    my $got = str2time($string, format => 'W3CDTF', precision => $precision);
    delta_within($got, $time, 1e-9, qq[str2time($string, format => 'W3CDTF', precision => $precision)]);
  }
}

done_testing();
