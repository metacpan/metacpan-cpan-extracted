#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

# Zone before year: DDD MMM (_D|DD) hh:mm:ss ZONE YYYY
{
  my @tests = (
    [ 'Mon Dec 24 15:30:45 +0100 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => 60
      }
    ],

    [ 'Thu Jan  1 00:00:00 UTC 1970' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'UTC',
        tz_offset => 0
      }
    ],

    [ 'Sun Nov  6 08:49:37 GMT 1994' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Mon Dec 24 15:30:45 -0500 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => -300
      }
    ],

    # Timezone abbreviation
    [ 'Mon Dec 24 15:30:45 CET 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_abbrev => 'CET'
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'Unix');
    is_deeply($got, $exp, qq[str2date('$string', format => 'Unix')]);
  }
}

# Year before zone: DDD MMM (_D|DD) hh:mm:ss YYYY ZONE
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

    [ 'Thu Jan  1 00:00:00 1970 UTC' => {
        year      => 1970,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'UTC',
        tz_offset => 0
      }
    ],

    [ 'Mon Dec 24 15:30:45 2012 -0500' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_offset => -300
      }
    ],

    [ 'Sun Nov  6 08:49:37 1994 GMT' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'Unix');
    is_deeply($got, $exp, qq[str2date('$string', format => 'Unix')]);
  }
}

# Space-padded single-digit day
{
  my @tests = (
    [ 'Sun Nov  6 08:49:37 +0100 1994' => {
        year      => 1994,
        month     => 11,
        day       => 6,
        hour      => 8,
        minute    => 49,
        second    => 37,
        tz_offset => 60
      }
    ],

    [ 'Tue Jan  1 00:00:00 UTC 2013' => {
        year      => 2013,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'UTC',
        tz_offset => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'Unix');
    is_deeply($got, $exp, qq[str2date('$string', format => 'Unix')]);
  }
}

# str2time
{
  my @tests = (
    [ 'Thu Jan  1 00:00:00 UTC 1970'    =>  0          ],
    [ 'Mon Dec 24 15:30:45 +0100 2012'  =>  1356359445 ],
    [ 'Mon Dec 24 14:30:45 UTC 2012'    =>  1356359445 ],
    [ 'Mon Dec 24 09:30:45 -0500 2012'  =>  1356359445 ],
    [ 'Mon Dec 24 14:30:45 2012 +0000'  =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'Unix');
    is($got, $time, qq[str2time('$string', format => 'Unix')]);
  }
}

# time2str
{
  my @tests = (
    [ 'Thu Jan  1 00:00:00 UTC 1970',
      0,
      {}
    ],

    [ 'Mon Dec 24 15:30:45 +0100 2012',
      1356359445,
      { offset => 60 }
    ],

    [ 'Mon Dec 24 09:30:45 -0500 2012',
      1356359445,
      { offset => -300 }
    ],

    [ 'Mon Dec 24 14:30:45 UTC 2012',
      1356359445,
      {}
    ],

    # Single-digit day space-padded
    [ 'Sun Nov  6 08:49:37 UTC 1994',
      784111777,
      {}
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time, $params) = @$case;

    my $params_str = join ', ', map {
        sprintf '%s => %d', $_, $params->{$_}
    } keys %$params;

    my $got = time2str($time, format => 'Unix', %$params);
    is($got, $string, qq[time2str($time, format => 'Unix', $params_str)]);
  }
}

done_testing();
