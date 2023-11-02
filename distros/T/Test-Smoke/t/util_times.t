#! /usr/bin/perl -w
use strict;

# $Id$

use Test::More;
my $verbose = 0;

my( @diffs, @fixed );
BEGIN {
    @diffs = (
        { diff => 1 * 60*60 + 42 * 60 + 42.042,
          str  => '1 hour 42 minutes' },
        { diff => 1 * 24*60*60 + 2 * 60*60 + 4 * 60 + 2.042,
          str  => '1 day 2 hours 4 minutes' },
        { diff => 42 * 60 + 42.042,
          str  => '42 minutes 42 seconds' },
        { diff => 4 * 60 + 42.042,
          str  => '4 minutes 42.042 seconds' },
        { diff => 4 * 60*60 + 2.042,
          str  => '4 hours' },
        { diff => 2 * 24*60*60 + 4 * 60 + 2,
          str  => '2 days 4 minutes' },
        { diff => 60,
          str  => '1 minute' },
        # 3 x GitHubIssue#78
        { diff => 20512/18,
          str  => '19 minutes' },
        { diff => 3 * 60 + 59.995,
          str  => '3 minutes 59.995 seconds' },
        { diff => 3 * 60 + 59.99951,
          str  => '4 minutes' },
    );

    use Time::Local;
    @fixed = ( 0, 42, 21, 1, 7, 2003 );
    use subs qw( time localtime );
    sub time      { timelocal( @fixed ) };
    sub localtime { CORE::localtime( timelocal( @fixed ) ) };
    *CORE::GLOBAL::time      = \&time;
    *CORE::GLOBAL::localtime = \&localtime;
}
BEGIN { use_ok "Test::Smoke::Util", qw( time_in_hhmm calc_timeout ) }

# Tests for time_in_hhmm()
foreach my $diff ( @diffs ) {
    is time_in_hhmm( $diff->{diff} ), $diff->{str},
       "time_in_hhmm($diff->{diff}) $diff->{str}";
}

# Tests for calc_timeout()
my @localtime = (localtime)[0..5]; $localtime[5] += 1900;
is_deeply \@localtime, \@fixed, "localtime() is fixed at " . localtime;

is calc_timeout( '22:00', time ), 60*18,    "Absolute time (22:00) from 21:42";
is calc_timeout( '20:42', time ), 60*60*23, "Absolute time (20:42) from 21:42";
is calc_timeout( '21:42', time ), 60*60*24, "Absolute time (21:42) from 21:42";

SKIP: {
    $] < 5.005 and skip "Will not work on this perl ($])", 3;
    is calc_timeout( '22:00' ), 60*18,    "Absolute time (22:00) from 21:42";
    is calc_timeout( '20:42' ), 60*60*23, "Absolute time (20:42) from 21:42";
    is calc_timeout( '21:42' ), 60*60*24, "Absolute time (21:42) from 21:42";
}

is( calc_timeout( '+0:42' ), 60*42, "Relative time +0:42" );
is( calc_timeout( '+47:45' ), 60*(60*47+45), "Relative time +47:45" );
is( calc_timeout( '' ), 0, 'No input' );

done_testing();
