#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

# str2date - extended format
{
  my @tests = (
    [ '0001-01-01' => { year =>    1, month =>  1, day => 1 } ],
    [ '9999-12-31' => { year => 9999, month => 12, day => 31 } ],
    [ '2012-12-24' => { year => 2012, month => 12, day => 24 } ],

    [ '2012-12-24T15' => {
        year => 2012, month => 12, day => 24,
        hour => 15
      }
    ],

    [ '2012-12-24T15:30' => {
        year => 2012, month  => 12, day => 24,
        hour => 15,   minute => 30
      }
    ],

    [ '2012-12-24T15:30:45' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45
      }
    ],

    [ '2012-12-24T15:30:45Z' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '2012-12-24T15Z' => {
        year => 2012, month => 12, day => 24,
        hour => 15,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '2012-12-24T15:30Z' => {
        year => 2012, month  => 12, day => 24,
        hour => 15,   minute => 30,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '2012-12-24T15:30:45.500Z' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45,
        nanosecond => 500_000_000,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '2012-12-24T15:30:45,500Z' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45,
        nanosecond => 500_000_000,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '2012-12-24T15:30:45.123456789Z' => {
        year => 2012, month => 12, day    => 24,
        hour => 15,  minute => 30, second => 45,
        nanosecond => 123_456_789,
        tz_utc => 'Z', tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ISO8601')]);
  }
}

# str2date - basic format
{
  my @tests = (
    [ '00010101' => { year =>   1,  month =>  1, day =>  1 } ],
    [ '99991231' => { year => 9999, month => 12, day => 31 } ],
    [ '20121224' => { year => 2012, month => 12, day => 24 } ],

    [ '20121224T15' => {
        year => 2012, month => 12, day => 24,
        hour => 15
      }
    ],

    [ '20121224T1530' => {
        year => 2012, month  => 12, day => 24,
        hour => 15,   minute => 30
      }
    ],

    [ '20121224T153045' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45
      }
    ],

    [ '20121224T153045Z' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '20121224T153045.500Z' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45,
        nanosecond => 500_000_000,
        tz_utc => 'Z', tz_offset => 0
      }
    ],

    [ '20121224T153045,123456789Z' => {
        year => 2012, month  => 12, day    => 24,
        hour => 15,   minute => 30, second => 45,
        nanosecond => 123_456_789,
        tz_utc => 'Z', tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ISO8601')]);
  }
}

# decimal fractions on hour and minute
{
  my @tests = (
    # decimal hour (extended)
    [ '.0Z',  { minute => 0 } ],
    [ '.1Z',  { minute => 6 } ],
    [ '.25Z', { minute => 15 } ],
    [ '.5Z',  { minute => 30 } ],
    [ '.75Z', { minute => 45 } ],
  );

  my $base_str = '2012-12-24T15';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15,
    tz_utc => 'Z', tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $time_exp) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, %$time_exp};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

{
  my @tests = (
    [ '.0Z',  { second =>  0 } ],
    [ '.25Z', { second => 15 } ],
    [ '.5Z',  { second => 30 } ],
    [ '.75Z', { second => 45 } ],
  );

  my $base_str = '2012-12-24T15:30';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15, minute => 30,
    tz_utc => 'Z', tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $time_exp) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, %$time_exp};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

{
  my @tests = (
    [ '.5Z',  { minute => 30 } ],
    [ '.75Z', { minute => 45 } ],
  );

  my $base_str = '20121224T15';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15,
    tz_utc => 'Z', tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $time_exp) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, %$time_exp};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

{
  my @tests = (
    [ '.5Z',  { second => 30 } ],
    [ '.75Z', { second => 45 } ],
  );

  my $base_str = '20121224T1530';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15, minute => 30,
    tz_utc => 'Z', tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $time_exp) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, %$time_exp};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

# fractional seconds
{
  my @tests = (
    [ '.123456789Z', 123456789 ],
    [ '.12345678Z',  123456780 ],
    [ '.1234567Z',   123456700 ],
    [ '.123456Z',    123456000 ],
    [ '.12345Z',     123450000 ],
    [ '.1234Z',      123400000 ],
    [ '.123Z',       123000000 ],
    [ '.12Z',        120000000 ],
    [ '.1Z',         100000000 ],
    [ '.9Z',         900000000 ],
    [ '.999999999Z', 999999999 ],
    [ '.0Z',                 0 ],
    [ '.000000000Z',         0 ],
  );

  my $base_str = '2012-12-24T15:30:45';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15, minute => 30, second => 45,
    tz_utc => 'Z', tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $nanosecond) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, nanosecond => $nanosecond};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

# timezone offsets - extended format
{
  my @tests = (
    [ '-23:59', -1439 ],
    [ '-12:00',  -720 ],
    [ '-05:00',  -300 ],
    [ '-05',     -300 ],
    [ '-01:00',   -60 ],
    [ '-01',      -60 ],
    [ '-00:01',    -1 ],
    [ '+00:01',     1 ],
    [ '+01:00',    60 ],
    [ '+01',       60 ],
    [ '+05:30',   330 ],
    [ '+14:00',   840 ],
    [ '+23:59',  1439 ],
  );

  my $base_str = '2012-12-24T15:30:45';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15, minute => 30, second => 45,
  );

  foreach my $case (@tests) {
    my ($zone, $offset) = @$case;
    my $str = $base_str . $zone;
    my $exp = {%base_exp, tz_offset => $offset};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

# timezone offsets - basic format
{
  my @tests = (
    [ '-0500',  -300 ],
    [ '-05',    -300 ],
    [ '-0100',   -60 ],
    [ '-01',     -60 ],
    [ '+0100',    60 ],
    [ '+01',      60 ],
    [ '+0530',   330 ],
    [ '+2359',  1439 ],
  );

  my $base_str = '20121224T153045';
  my %base_exp = (
    year => 2012, month => 12, day => 24,
    hour => 15, minute => 30, second => 45,
  );

  foreach my $case (@tests) {
    my ($zone, $offset) = @$case;
    my $str = $base_str . $zone;
    my $exp = {%base_exp, tz_offset => $offset};
    my $got = str2date($str, format => 'ISO8601');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ISO8601')]);
  }
}

# str2time
{
  my @tests = (
    # extended
    [ '1970-01-01T00:00:00Z'       =>  0          ],
    [ '1970-01-01T01:00:00+01:00'  =>  0          ],
    [ '1969-12-31T19:00:00-05:00'  =>  0          ],
    [ '2012-12-24T15:30:45+01:00'  =>  1356359445 ],
    [ '2012-12-24T14:30:45Z'       =>  1356359445 ],
    [ '2012-12-24T09:30:45-05:00'  =>  1356359445 ],

    # basic
    [ '19700101T000000Z'           =>  0          ],
    [ '19700101T010000+0100'       =>  0          ],
    [ '20121224T153045+0100'       =>  1356359445 ],
    [ '20121224T143045Z'           =>  1356359445 ],
    [ '20121224T093045-0500'       =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'ISO8601');
    is($got, $time, qq[str2time('$string', format => 'ISO8601')]);
  }
}

# str2time with fractional seconds
{
  my @tests = (
    [ '2012-12-24T15:30:45.500Z',    3, 1e-3, 1356363045.5      ],
    [ '2012-12-24T15:30:45.123456Z', 6, 1e-6, 1356363045.123456 ],
    [ '20121224T153045.500Z',         3, 1e-3, 1356363045.5      ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $epsilon, $time) = @$case;
    my $got = str2time($string, format => 'ISO8601', precision => $precision);
    delta_within($got, $time, $epsilon, qq[str2time('$string', format => 'ISO8601', precision => $precision)]);
  }
}

# str2time precision truncation
{
  my @tests = (
    [ '1970-01-01T00:00:00.123456789Z', 9, 0.123456789 ],
    [ '1970-01-01T00:00:00.123456789Z', 6, 0.123456    ],
    [ '1970-01-01T00:00:00.123456789Z', 3, 0.123       ],
    [ '1970-01-01T00:00:00.999999999Z', 3, 0.999       ],
    [ '1970-01-01T00:00:00.999999999Z', 0, 0           ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $time) = @$case;
    my $got = str2time($string, format => 'ISO8601', precision => $precision);
    delta_within($got, $time, 1e-9, qq[str2time('$string', format => 'ISO8601', precision => $precision)]);
  }
}

# time2str
{
  my @tests = (
    [ '1970-01-01T00:00:00Z',
      0,
      {}
    ],

    [ '2012-12-24T15:30:45+01:00',
      1356359445,
      { offset => 60 }
    ],

    [ '2012-12-24T09:30:45-05:00',
      1356359445,
      { offset => -300 }
    ],

    [ '2012-12-24T14:30:45Z',
      1356359445,
      {}
    ],

    [ '2012-12-24T14:30:45.500Z',
      1356359445,
      { precision => 3, nanosecond => 500_000_000 }
    ],

    [ '2012-12-24T15:30:45.123456+01:00',
      1356359445,
      { precision => 6, nanosecond => 123_456_000, offset => 60 }
    ],

    [ '9999-12-31T23:59:59Z',
      253402300799,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'ISO8601', %$params);
    is($got, $string, qq[time2str($time, format => 'ISO8601', $params_str)]);
  }
}

# time2str nanosecond override
{
  my $time = 1356363045.999999;

  my $got = time2str($time, format => 'ISO8601', nanosecond => 500_000_000);
  is($got, '2012-12-24T15:30:45.500Z', 'nanosecond overrides fractional time');

  $got = time2str($time, format => 'ISO8601', nanosecond => 0);
  is($got, '2012-12-24T15:30:45Z', 'nanosecond => 0 suppresses fraction');

  $got = time2str($time, format => 'ISO8601', nanosecond => 0, precision => 3);
  is($got, '2012-12-24T15:30:45.000Z', 'nanosecond => 0 with precision zero-pads');
}

done_testing();
