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
    [ '7001010000Z' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    # hhmmss with Z
    [ '121224153045Z' => {
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

    # hhmm with Z
    [ '1212241530Z' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    # With numeric offset
    [ '121224153045+0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ '121224153045-0500' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => -300
      }
    ],

    # Two-digit year pivot (default 1950)
    [ '491231235959Z' => {
        year      => 2049,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    [ '500101000000Z' => {
        year      => 1950,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

    [ '990101000000Z' => {
        year      => 1999,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ASN1UT');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ASN1UT')]);
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

  my $base_str = '121224153045';
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
    my $got = str2date($str, format => 'ASN1UT');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ASN1UT')]);
  }
}

{
  my @tests = (
    [ '7001010000Z'       =>  0 ],
    [ '700101010000+0100' =>  0 ],
    [ '691231190000-0500' =>  0 ],
    [ '121224153045+0100' =>  1356359445   ],
    [ '121224143045Z'     =>  1356359445   ],
    [ '121224093045-0500' =>  1356359445   ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'ASN1UT');
    is($got, $time, qq[str2time($string, format => 'ASN1UT')]);
  }
}

{
  my @tests = (
    [ '121224153045Z',
      1356363045,
      {}
    ],
    [ '121224153045+0100',
      1356359445,
      { offset => 60 }
    ],
    [ '121224093045-0500',
      1356359445,
      { offset => -300 }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'ASN1UT', %$params);
    is($got, $string, qq[time2str($time, format => 'ASN1UT', $params_str)]);
  }
}

# Custom pivot year
{
  my $got = str2date('000101000000Z', format => 'ASN1UT', pivot_year => 2000);
  is($got->{year}, 2000, 'pivot_year => 2000: year 00 maps to 2000');
}

{
  my $got = str2date('010101000000Z', format => 'ASN1UT', pivot_year => 2000);
  is($got->{year}, 2001, 'pivot_year => 2000: year 01 maps to 2001');
}

{
  my $got = str2date('490101000000Z', format => 'ASN1UT', pivot_year => 1950);
  is($got->{year}, 2049, 'pivot_year => 1950: year 49 maps to 2049');
}

{
  my $got = str2date('500101000000Z', format => 'ASN1UT', pivot_year => 1950);
  is($got->{year}, 1950, 'pivot_year => 1950: year 50 maps to 1950');
}

{
  my $got = str2date('000101000000Z', format => 'ASN1UT', pivot_year => 1900);
  is($got->{year}, 1900, 'pivot_year => 1900: year 00 maps to 1900');
}

{
  my $got = str2date('490101000000Z', format => 'ASN1UT', pivot_year => 1900);
  is($got->{year}, 1949, 'pivot_year => 1900: year 49 maps to 1949');
}

done_testing();
