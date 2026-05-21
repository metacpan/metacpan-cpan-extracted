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
    [ '20121224' => { year => 2012, month => 12, day => 24 } ],
    [ '00010101' => { year =>    1, month =>  1, day =>  1 } ],
    [ '99991231' => { year => 9999, month => 12, day => 31 } ],

    # date-time without UTC designator
    [ '20121224T153045' => {
        year   => 2012,
        month  => 12,
        day    => 24,
        hour   => 15,
        minute => 30,
        second => 45
      }
    ],

    [ '19700101T000000' => {
        year   => 1970,
        month  => 1,
        day    => 1,
        hour   => 0,
        minute => 0,
        second => 0
      }
    ],

    # date-time with UTC designator
    [ '20121224T153045Z' => {
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

    [ '19700101T000000Z' => {
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

    [ '99991231T235959Z' => {
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
    my $got = str2date($string, format => 'RFC5545');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC5545')]);
  }
}

# str2time
{
  my @tests = (
    [ '19700101T000000Z' =>           0 ],
    [ '20121224T143045Z' =>  1356359445 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'RFC5545');
    is($got, $time, qq[str2time('$string', format => 'RFC5545')]);
  }
}

# time2str
{
  my @tests = (
    [ '19700101T000000Z',            0 ],
    [ '20121224T143045Z',   1356359445 ],
    [ '99991231T235959Z', 253402300799 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = time2str($time, format => 'RFC5545');
    is($got, $string, qq[time2str($time, format => 'RFC5545')]);
  }
}

# iCal alias
{
  my $string  = '20121224T153045Z';
  my $got_ical = str2date($string, format => 'iCal');
  my $got_rfc  = str2date($string, format => 'RFC5545');
  is_deeply($got_ical, $got_rfc, 'iCal alias parses same as RFC5545');
}

done_testing();
