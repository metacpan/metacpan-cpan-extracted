#!./perl

use strict;
use warnings;

use POSIX;
use Test::More 0.96;
use Time::Local;

{
    local $ENV{TZ} = 'Europe/Vienna';
    POSIX::tzset();

    # 2001-10-28 02:30:00 - could be either summer or standard time,
    # prefer earlier of the two, in this case summer
    my $time = timelocal( 0, 30, 2, 28, 9, 101 );
    is(
        $time, 1004229000,
        'timelocal prefers earlier epoch in the presence of a DST change'
    );

    local $ENV{TZ} = 'America/Chicago';
    POSIX::tzset();

    # Same local time in America/Chicago.  There is a transition here
    # as well.
    $time = timelocal( 0, 30, 1, 28, 9, 101 );
    is(
        $time, 1004250600,
        'timelocal prefers earlier epoch in the presence of a DST change'
    );

    $time = timelocal( 0, 30, 2, 1, 3, 101 );
    is(
        $time, 986113800,
        'timelocal for non-existent time gives you the time one hour later'
    );

    local $ENV{TZ} = 'Australia/Sydney';
    POSIX::tzset();

    # 2001-03-25 02:30:00 in Australia/Sydney.  This is the transition
    # _to_ summer time.  The southern hemisphere transitions are
    # opposite those of the northern.
    $time = timelocal( 0, 30, 2, 25, 2, 101 );
    is(
        $time, 985447800,
        'timelocal prefers earlier epoch in the presence of a DST change'
    );

    $time = timelocal( 0, 30, 2, 28, 9, 101 );
    is(
        $time, 1004200200,
        'timelocal for non-existent time gives you the time one hour later'
    );

    local $ENV{TZ} = 'Europe/London';
    POSIX::tzset();
    $time = timelocal( localtime(1111917720) );
    is(
        $time, 1111917720,
        'timelocal for round trip bug on date of DST change for Europe/London'
    );

    # There is no 1:00 AM on this date, as it leaps forward to
    # 2:00 on the DST change - this should return 2:00 per the
    # docs.
    is(
        ( localtime( timelocal( 0, 0, 1, 27, 2, 2005 ) ) )[2], 2,
        'hour is 2 when given 1:00 AM on Europe/London date change'
    );

    is(
        ( localtime( timelocal( 0, 0, 2, 27, 2, 2005 ) ) )[2], 2,
        'hour is 2 when given 2:00 AM on Europe/London date change'
    );
}

done_testing();
