#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

# str2date
{
  my @tests = (
    # Two-digit year (UTCTime)
    [ '700101000000Z' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

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

    # Two-digit year pivot boundary (default 1950)
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

    # Four-digit year (GeneralizedTime)
    [ '20500101000000Z' => {
        year      => 2050,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'Z',
        tz_offset => 0
      }
    ],

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
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'RFC5280');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC5280')]);
  }
}

# str2time
{
  my @tests = (
    [ '700101000000Z'     =>  0          ],
    [ '121224143045Z'     =>  1356359445 ],
    [ '20121224143045Z'   =>  1356359445 ],
    [ '20500101000000Z'   =>  2524608000 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'RFC5280');
    is($got, $time, qq[str2time('$string', format => 'RFC5280')]);
  }
}

# time2str
{
  my @tests = (
    # Before 2050: UTCTime (two-digit year)
    [ '700101000000Z',
      0,
    ],

    [ '121224143045Z',
      1356359445,
    ],

    # At 2050 boundary: GeneralizedTime (four-digit year)
    [ '20500101000000Z',
      2524608000,
    ],

    [ '99991231235959Z',
      253402300799,
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = time2str($time, format => 'RFC5280');
    is($got, $string, qq[time2str($time, format => 'RFC5280')]);
  }
}

# x509 alias
{
  my $string   = '121224153045Z';
  my $got_x509 = str2date($string, format => 'x509');
  my $got_rfc  = str2date($string, format => 'RFC5280');
  is_deeply($got_x509, $got_rfc, 'x509 alias parses same as RFC5280');
}

done_testing();
