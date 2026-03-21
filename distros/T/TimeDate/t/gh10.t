use strict;
use warnings;

# GH#10 / RT#80649: Wrong timezone abbreviation during DST fall-back
#
# format_Z was calling timelocal() to reconstruct the original epoch from
# broken-down time.  During the "fall-back" hour, the broken-down time is
# ambiguous (1:xx AM occurs twice: once in PDT and once in PST).  timelocal()
# resolves the ambiguity to the first occurrence (PDT), returning the PDT
# epoch (offset -25200).  tz_name(-25200, dst=0) then finds -25200 in %zoneOff
# as "mst" (Mountain Standard), yielding MST instead of PST.
#
# Fix: use the original epoch stored in $_[0]->[9] instead of timelocal().
#
# The TZ is set in a BEGIN block so the C library timezone is initialised
# before any module loads and before any localtime/tzset calls happen.
# Using a runtime $ENV{TZ} assignment after `use` statements is unreliable
# because `use` executes at compile time, and on some platforms restoring a
# `local $ENV{TZ}` automatically resets the C library timezone, which a later
# POSIX::tzset() call may not fully undo.

BEGIN {
    $ENV{TZ} = 'America/Los_Angeles';
    require POSIX;
    eval { POSIX::tzset() };
}

use POSIX qw();
use Test::More;
use Date::Format qw(time2str);

# Skip the whole file if the platform does not support IANA timezone names.
# Use epoch 1352019262 (2012-11-04 01:04:22 PDT): DST=1 in America/Los_Angeles
# but DST=0 in UTC, so this check actually distinguishes the two and won't
# produce a false-positive on a UTC-only system.
my $has_la_tz = eval {
    my @lt = localtime(1352019262);    # 2012-11-04 01:04:22 PDT (before fall-back)
    $lt[8] == 1;                       # Expect DST flag = 1 in PDT
};
plan( skip_all => "system does not support America/Los_Angeles timezone" )
    unless $has_la_tz;

plan tests => 3;

# 2012-11-04 01:25:05 PST — the second occurrence of 01:xx AM after fall-back
# This is the timestamp from the original bug report that returned MST.
is( time2str("%Z", 1352021105), "PST",
    "GH#10/RT#80649: repeated hour after fall-back formats as PST, not MST" );

# 2012-11-04 01:54:22 PDT — before the fall-back (first occurrence of 01:xx AM)
is( time2str("%Z", 1352019262), "PDT",
    "GH#10/RT#80649: pre-fall-back timestamp formats as PDT" );

# 2012-11-04 02:25:05 PST — after the repeated hour, clearly PST
is( time2str("%Z", 1352024705), "PST",
    "GH#10/RT#80649: post-repeated-hour timestamp formats as PST" );
