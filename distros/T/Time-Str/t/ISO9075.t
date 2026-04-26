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
    [ '0001-01-01' => {
        year  => 1,
        month => 1,
        day   => 1
      }
    ],

    [ '9999-12-31' => {
        year  => 9999,
        month => 12,
        day   => 31
      }
    ],

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

    [ '2012-12-24 15:30:45 -05:00' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => -300
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

    [ '2012-12-24 15:30:45.123456789 +00:00' => {
        year       => 2012,
        month      => 12,
        day        => 24,
        hour       => 15,
        minute     => 30,
        second     => 45,
        nanosecond => 123_456_789,
        tz_offset  => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ISO9075');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ISO9075')]);
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
    [ '.9Z',         900000000 ],
    [ '.999999999Z', 999999999 ],
    [ '.0Z',                 0 ],
    [ '.000000000Z',         0 ],
  );

  my $base_str = '2012-12-24 15:30:45';
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
    (my $frac = $fraction) =~ s/Z$//;
    my $str = $base_str . $frac . ' +00:00';
    my $exp = {%base_exp, nanosecond => $nanosecond };
    my $got = str2date($str, format => 'ISO9075');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO9075')]);
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

  my $base_str = '2012-12-24 15:30:45 ';
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
    my $got = str2date($str, format => 'ISO9075');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO9075')]);
  }
}

{
  my @tests = (
    [ '1970-01-01 00:00:00 +00:00'     =>  0 ],
    [ '1970-01-01 01:00:00 +01:00'     =>  0 ],
    [ '1969-12-31 19:00:00 -05:00'     =>  0 ],
    [ '2012-12-24 15:30:45 +01:00'     =>  1356359445   ],
    [ '2012-12-24 14:30:45 +00:00'     =>  1356359445   ],
    [ '2012-12-24 09:30:45 -05:00'     =>  1356359445   ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'ISO9075');
    is($got, $time, qq[str2time('$string', format => 'ISO9075')]);
  }
}

{
  my @tests = (
    [ '2012-12-24 15:30:45.500 +01:00',
      1356359445,
      { precision => 3, nanosecond => 500_000_000, offset => 60 }
    ],
    [ '2012-12-24 14:30:45 +00:00',
      1356359445,
      {}
    ],
    [ '2012-12-24 09:30:45 -05:00',
      1356359445,
      { offset => -300 }
    ],
    [ '2012-12-24 15:30:45.123456 +00:00',
      1356363045,
      { precision => 6, nanosecond => 123_456_000 }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'ISO9075', %$params);
    is($got, $string, qq[time2str($time, format => 'ISO9075', $params_str)]);
  }
}

{
  my $string  = '2012-12-24 15:30:45 +01:00';
  my $got_sql = str2date($string, format => 'SQL');
  my $got_iso = str2date($string, format => 'ISO9075');
  is_deeply($got_sql, $got_iso, 'SQL alias parses same as ISO9075');
}

done_testing();
