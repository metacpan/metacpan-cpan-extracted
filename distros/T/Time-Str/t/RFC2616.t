#!perl
use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok('Time::Str', qw[str2time str2date time2str]);
}

# IMF-fixdate
{
  my @tests = (
    [ 'Mon, 24 Dec 2012 15:30:45 GMT' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Tue, 01 Jan 2013 00:00:00 GMT' => {
        year      => 2013,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Sat, 01 Jan 0001 00:00:00 GMT' => {
        year      => 1,
        month     => 1,
        day       => 1,
        hour      => 0,
        minute    => 0,
        second    => 0,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Fri, 31 Dec 9999 23:59:59 GMT' => {
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
    my $got = str2date($string, format => 'RFC2616');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC2616')]);
  }
}

# RFC 850
{
  my @tests = (
    [ 'Monday, 24-Dec-12 15:30:45 GMT' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Sunday, 06-Nov-94 08:49:37 GMT' => {
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
    my $got = str2date($string, format => 'RFC2616');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC2616')]);
  }
}

# ANSI C's ctime
{
  my @tests = (
    [ 'Mon Dec 24 15:30:45 2012' => {
        year      => 2012,
        month     => 12,
        day       => 24,
        hour      => 15,
        minute    => 30,
        second    => 45,
        tz_utc    => 'GMT',
        tz_offset => 0
      }
    ],

    [ 'Sun Nov  6 08:49:37 1994' => {
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
    my $got = str2date($string, format => 'RFC2616');
    is_deeply($got, $exp, qq[str2date('$string', format => 'RFC2616')]);
  }
}

{
  my @tests = (
    [ 'Thu, 01 Jan 1970 00:00:00 GMT'   =>  0 ],
    [ 'Mon, 24 Dec 2012 14:30:45 GMT'   =>  1356359445 ],
    [ 'Mon, 24 Dec 2012 15:30:45 GMT'   =>  1356363045 ],
    [ 'Fri, 31 Dec 9999 23:59:59 GMT'   =>  253402300799 ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = str2time($string, format => 'RFC2616');
    is($got, $time, qq[str2time('$string', format => 'RFC2616')]);
  }
}

{
  my @tests = (
    [ 'Thu, 01 Jan 1970 00:00:00 GMT',  0 ],
    [ 'Mon, 24 Dec 2012 14:30:45 GMT',  1356359445 ],
    [ 'Mon, 24 Dec 2012 15:30:45 GMT',  1356363045 ],

    # Single-digit day must be zero-padded in IMF-fixdate
    [ 'Sun, 06 Nov 1994 08:49:37 GMT',  784111777 ],

    # Offset is ignored; output is always GMT
    [ 'Mon, 24 Dec 2012 14:30:45 GMT',
      1356359445,
    ],
  );

  foreach my $case (@tests) {
    my ($string, $time) = @$case;
    my $got = time2str($time, format => 'RFC2616');
    is($got, $string, qq[time2str($time, format => 'RFC2616')]);
  }
}

# RFC7231 and HTTP aliases
{
  my $string = 'Mon, 24 Dec 2012 15:30:45 GMT';
  my $got_7231 = str2date($string, format => 'RFC7231');
  my $got_http = str2date($string, format => 'HTTP');
  my $got_2616 = str2date($string, format => 'RFC2616');

  is_deeply($got_7231, $got_2616, 'RFC7231 alias parses same as RFC2616');
  is_deeply($got_http, $got_2616, 'HTTP alias parses same as RFC2616');
}

done_testing();
