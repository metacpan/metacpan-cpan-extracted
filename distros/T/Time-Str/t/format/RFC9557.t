#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

# str2date
{
  my @tests = (
    # Z with single tag
    [ '2012-12-24T15:30:45Z[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_utc        => 'Z',
        tz_offset     => 0,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # offset with single tag
    [ '2012-12-24T15:30:45+01:00[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_offset     => 60,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # negative offset with tag
    [ '2012-12-24T09:30:45-05:00[America/New_York]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 9,
        minute        => 30,
        second        => 45,
        tz_offset     => -300,
        tz_annotation => '[America/New_York]'
      }
    ],

    # multiple tags
    [ '2012-12-24T15:30:45+01:00[Europe/Stockholm][u-ca-hebrew]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_offset     => 60,
        tz_annotation => '[Europe/Stockholm][u-ca-hebrew]'
      }
    ],

    # fractional seconds with tag
    [ '2012-12-24T15:30:45.500Z[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        nanosecond    => 500_000_000,
        tz_utc        => 'Z',
        tz_offset     => 0,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # nanosecond precision with tag
    [ '2012-12-24T15:30:45.123456789+05:30[Asia/Kolkata]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        nanosecond    => 123_456_789,
        tz_offset     => 330,
        tz_annotation => '[Asia/Kolkata]'
      }
    ],

    # without tag (same as RFC 3339)
    [ '2012-12-24T15:30:45Z' => {
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

    # lowercase t separator
    [ '2012-12-24t15:30:45Z[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_utc        => 'Z',
        tz_offset     => 0,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # space separator
    [ '2012-12-24 15:30:45Z[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_utc        => 'Z',
        tz_offset     => 0,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # lowercase z
    [ '2012-12-24T15:30:45z[Europe/Stockholm]' => {
        year          => 2012,
        month         => 12,
        day           => 24,
        hour          => 15,
        minute        => 30,
        second        => 45,
        tz_utc        => 'z',
        tz_offset     => 0,
        tz_annotation => '[Europe/Stockholm]'
      }
    ],

    # boundaries
    [ '0001-01-01T00:00:00Z[Etc/UTC]' => {
        year          => 1,
        month         => 1,
        day           => 1,
        hour          => 0,
        minute        => 0,
        second        => 0,
        tz_utc        => 'Z',
        tz_offset     => 0,
        tz_annotation => '[Etc/UTC]'
      }
    ],

    [ '9999-12-31T23:59:59Z[Etc/UTC]' => {
        year          => 9999,
        month         => 12,
        day           => 31,
        hour          => 23,
        minute        => 59,
        second        => 59,
        tz_utc        => 'Z',
        tz_offset     => 0,
        tz_annotation => '[Etc/UTC]'
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'RFC9557');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC9557')]);
  }
}

# various annotation tag values
{
  my @tests = (
    [ '[Europe/Stockholm]' ],
    [ '[America/New_York]' ],
    [ '[Asia/Kolkata]' ],
    [ '[Etc/UTC]' ],
    [ '[u-ca-hebrew]' ],
    [ '[!u-ca-hebrew]' ],
    [ '[Europe/Stockholm][u-ca-hebrew]' ],
  );

  my $base_str = '2012-12-24T15:30:45Z';
  my %base_exp = (
    year      => 2012,
    month     => 12,
    day       => 24,
    hour      => 15,
    minute    => 30,
    second    => 45,
    tz_utc    => 'Z',
    tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($tag) = @$case;
    my $str = $base_str . $tag;
    my $exp = {%base_exp, tz_annotation => $tag};
    my $got = str2date($str, format => 'RFC9557');
    is_deeply($got, $exp, qq[str2date('$str', format => 'RFC9557')]);
  }
}

# timezone offsets
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
    my $got = str2date($str, format => 'RFC9557');
    is_deeply($got, $exp, qq[str2date('$str', format => 'RFC9557')]);
  }
}

# fractional seconds
{
  my @tests = (
    [ '.123456789Z', 123456789 ],
    [ '.123Z',       123000000 ],
    [ '.1Z',         100000000 ],
    [ '.9Z',         900000000 ],
    [ '.999999999Z', 999999999 ],
    [ '.0Z',                 0 ],
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
    tz_utc    => 'Z',
    tz_offset => 0,
  );

  foreach my $case (@tests) {
    my ($fraction, $nanosecond) = @$case;
    my $str = $base_str . $fraction;
    my $exp = {%base_exp, nanosecond => $nanosecond};
    my $got = str2date($str, format => 'RFC9557');
    is_deeply($got, $exp, qq[str2date('$str', format => 'RFC9557')]);
  }
}

# str2time
{
  my @tests = (
    [ '1970-01-01T00:00:00Z'                           =>  0          ],
    [ '1970-01-01T00:00:00Z[Etc/UTC]'                   =>  0          ],
    [ '2012-12-24T15:30:45+01:00[Europe/Stockholm]'     =>  1356359445 ],
    [ '2012-12-24T14:30:45Z[Europe/Stockholm]'          =>  1356359445 ],
    [ '2012-12-24T09:30:45-05:00[America/New_York]'     =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'RFC9557');
    is($got, $time, qq[str2time('$string', format => 'RFC9557')]);
  }
}

# str2time with fractional seconds
{
  my @tests = (
    [ '2012-12-24T15:30:45.500Z[Etc/UTC]',    3, 1e-3, 1356363045.5      ],
    [ '2012-12-24T15:30:45.123456Z[Etc/UTC]',  6, 1e-6, 1356363045.123456 ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $epsilon, $time) = @$case;
    my $got = str2time($string, format => 'RFC9557', precision => $precision);
    delta_within($got, $time, $epsilon, qq[str2time('$string', format => 'RFC9557', precision => $precision)]);
  }
}

# time2str (formats as RFC 3339, no annotation)
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
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'RFC9557', %$params);
    is($got, $string, qq[time2str($time, format => 'RFC9557', $params_str)]);
  }
}

# IXDTF alias
{
  my $string   = '2012-12-24T15:30:45+01:00[Europe/Stockholm]';
  my $got_ixdtf = str2date($string, format => 'IXDTF');
  my $got_rfc   = str2date($string, format => 'RFC9557');
  is_deeply($got_ixdtf, $got_rfc, 'IXDTF alias parses same as RFC9557');
}

done_testing();
