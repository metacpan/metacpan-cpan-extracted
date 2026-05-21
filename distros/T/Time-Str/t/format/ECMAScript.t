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
    # with GMT prefix
    [ 'Mon Dec 24 2012 15:30:45 GMT+0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 60
      }
    ],

    [ 'Thu Jan 01 1970 00:00:00 GMT+0000' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Mon Dec 24 2012 09:30:45 GMT-0500' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 9,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => -300
      }
    ],

    # with UTC prefix
    [ 'Mon Dec 24 2012 15:30:45 UTC+0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'UTC',
        tz_offset => 60
      }
    ],

    # without GMT/UTC prefix
    [ 'Mon Dec 24 2012 15:30:45 +0100' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    # with parenthesized comment
    [ 'Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 60
      }
    ],

    [ 'Mon Dec 24 2012 09:30:45 GMT-0500 (Eastern Standard Time)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 9,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => -300
      }
    ],

    [ 'Mon Dec 24 2012 20:00:45 GMT+0530 (India Standard Time)' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 20,
        minute    => 0,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 330
      }
    ],

    # boundary
    [ 'Fri Dec 31 9999 23:59:59 GMT+0000' => {
        year      => 9999,
        month     => 12,
        day       => 31,
        hour      => 23,
        minute    => 59,
        second    => 59,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ECMAScript');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ECMAScript')]);
  }
}

# timezone offsets
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

  my $base_str = 'Mon Dec 24 2012 15:30:45 GMT';
  my %base_exp = (
    year   => 2012,
    month  => 12,
    day    => 24,
    hour   => 15,
    minute => 30,
    second => 45,
    tz_utc => 'GMT',
  );

  foreach my $case (@tests) {
    my ($zone, $offset) = @$case;
    my $str = $base_str . $zone;
    my $exp = {%base_exp, tz_offset => $offset};
    my $got = str2date($str, format => 'ECMAScript');
    is_deeply($got, $exp, qq[str2date('$str', format => 'ECMAScript')]);
  }
}

# str2time
{
  my @tests = (
    [ 'Thu Jan 01 1970 00:00:00 GMT+0000'                         =>  0          ],
    [ 'Thu Jan 01 1970 01:00:00 GMT+0100'                         =>  0          ],
    [ 'Wed Dec 31 1969 19:00:00 GMT-0500'                         =>  0          ],
    [ 'Mon Dec 24 2012 15:30:45 GMT+0100'                         =>  1356359445 ],
    [ 'Mon Dec 24 2012 14:30:45 GMT+0000'                         =>  1356359445 ],
    [ 'Mon Dec 24 2012 09:30:45 GMT-0500'                         =>  1356359445 ],
    [ 'Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)' =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'ECMAScript');
    is($got, $time, qq[str2time('$string', format => 'ECMAScript')]);
  }
}

# time2str
{
  my @tests = (
    [ 'Thu Jan 01 1970 00:00:00 GMT+0000',
      0,
      {}
    ],

    [ 'Mon Dec 24 2012 15:30:45 GMT+0100',
      1356359445,
      { offset => 60 }
    ],

    [ 'Mon Dec 24 2012 09:30:45 GMT-0500',
      1356359445,
      { offset => -300 }
    ],

    [ 'Mon Dec 24 2012 14:30:45 GMT+0000',
      1356359445,
      {}
    ],

    [ 'Sun Nov 06 1994 08:49:37 GMT+0000',
      784111777,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'ECMAScript', %$params);
    is($got, $string, qq[time2str($time, format => 'ECMAScript', $params_str)]);
  }
}

# JavaScript alias
{
  my $string = 'Mon Dec 24 2012 15:30:45 GMT+0100';
  my $got_js  = str2date($string, format => 'JavaScript');
  my $got_ecma = str2date($string, format => 'ECMAScript');
  is_deeply($got_js, $got_ecma, 'JavaScript alias parses same as ECMAScript');
}

done_testing();
