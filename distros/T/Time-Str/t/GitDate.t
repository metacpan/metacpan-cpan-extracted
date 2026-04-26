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

    [ 'Thu Jan 1 00:00:00 1970 +0000' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_offset => 0
      }
    ],

    [ 'Sun Nov 6 08:49:37 1994 -0500' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_offset => -300
      }
    ],

    [ 'Fri Dec 31 23:59:59 9999 +0000' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_offset => 0
      }
    ],

    [ 'Mon Dec 24 09:30:45 2012 -0500' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 9,
        minute    => 30,
        second    => 45,
        tz_offset => -300
      }
    ],

    [ 'Mon Dec 24 20:00:45 2012 +0530' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 20,
        minute    => 0,
        second    => 45,
        tz_offset => 330
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'Git');
    is_deeply($got, $exp, qq[str2date('$string', format => 'Git')]);
  }
}

# str2time
{
  my @tests = (
    [ 'Thu Jan 1 00:00:00 1970 +0000'   =>  0          ],
    [ 'Mon Dec 24 15:30:45 2012 +0100'  =>  1356359445 ],
    [ 'Mon Dec 24 14:30:45 2012 +0000'  =>  1356359445 ],
    [ 'Mon Dec 24 09:30:45 2012 -0500'  =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'Git');
    is($got, $time, qq[str2time('$string', format => 'Git')]);
  }
}

# time2str
{
  my @tests = (
    [ 'Thu Jan 1 00:00:00 1970 +0000',
      0,
      {}
    ],

    [ 'Mon Dec 24 15:30:45 2012 +0100',
      1356359445,
      { offset => 60 }
    ],

    [ 'Mon Dec 24 09:30:45 2012 -0500',
      1356359445,
      { offset => -300 }
    ],

    [ 'Mon Dec 24 14:30:45 2012 +0000',
      1356359445,
      {}
    ],

    # Single-digit day
    [ 'Sun Nov 6 08:49:37 1994 +0000',
      784111777,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'Git', %$params);
    is($got, $string, qq[time2str($time, format => 'Git', $params_str)]);
  }
}

done_testing();
