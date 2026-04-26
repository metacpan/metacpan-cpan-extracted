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
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'RFC4287');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC4287')]);
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
    my $got = str2time($string, format => 'RFC4287');
    is($got, $time, qq[str2time($string, format => 'RFC4287')]);
  }
}

{
  my @tests = (
    [ '2012-12-24T15:30:45.500Z',    3, 1e-3,  1356363045.5        ],
    [ '2012-12-24T15:30:45.123456Z', 6, 1e-6,  1356363045.123456   ],
    [ '2012-12-24T15:30:45.999999Z', 6, 1e-6,  1356363045.999999   ],
  );

  foreach my $case (@tests) {
    my ($string, $precision, $epsilon, $time) = @$case;

    {
      my $got = time2str($time, format => 'RFC4287', precision => $precision);
      is($got, $string, qq[time2str($time, format => 'RFC4287', precision => $precision)]);
    }
    {
      my $got = str2time($string, format => 'RFC4287', precision => $precision);
      delta_within($got, $time, $epsilon, qq[str2time($string, format => 'RFC4287', precision => $precision)]);
    }
  }
}

# ATOM alias
{
  my $string = '2012-12-24T15:30:45Z';
  my $got_atom   = str2date($string, format => 'ATOM');
  my $got_rfc    = str2date($string, format => 'RFC4287');

  is_deeply($got_atom, $got_rfc, 'ATOM alias parses same as RFC4287');
}

done_testing();
