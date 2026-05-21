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
    [ 'Mon Dec 24 15:30:45 2012' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30,
        second => 45
      }
    ],

    [ 'Sun Nov  6 08:49:37 1994' => {
        year   => 1994,
        month  => 11,
        day    => 6,
        hour   => 8,
        minute => 49,
        second => 37
      }
    ],

    [ 'Thu Jan  1 00:00:00 1970' => {
        year   => 1970,
        month  => 1,
        day    => 1,
        hour   => 0,
        minute => 0,
        second => 0
      }
    ],

    [ 'Sat Dec 31 23:59:59 2016' => {
        year   => 2016,
        month  => 12,
        day    => 31,
        hour   => 23,
        minute => 59,
        second => 59
      }
    ],

    [ 'Wed Feb 29 12:00:00 2012' => {
        year   => 2012,
        month  => 2,
        day    => 29,
        hour   => 12,
        minute => 0,
        second => 0
      }
    ],
  );

  foreach my $case (@tests) {
    my ($string, $exp) = @$case;
    my $got = str2date($string, format => 'ANSIC');
    is_deeply($got, $exp, qq[str2date('$string', format => 'ANSIC')]);
  }
}

{
  my @tests = (
    [ 'Thu Jan  1 00:00:00 1970', 0 ],
    [ 'Mon Dec 24 15:30:45 2012', 1356363045 ],
    [ 'Sun Nov  6 08:49:37 1994', 784111777  ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;

    {
      my $got = time2str($time, format => 'ANSIC');
      is($got, $string, qq[time2str($time, format => 'ANSIC')]);
    }
  }
}

{
  my $string = 'Mon Dec 24 15:30:45 2012';
  my $got_ctime = str2date($string, format => 'ctime');
  my $got_ansic = str2date($string, format => 'ANSIC');

  is_deeply($got_ctime, $got_ansic, 'ctime alias parses same as ANSIC');
}

done_testing();
