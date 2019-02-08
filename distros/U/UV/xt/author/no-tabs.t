use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/UV.pm',
    'lib/UV/Check.pm',
    'lib/UV/Handle.pm',
    'lib/UV/Idle.pm',
    'lib/UV/Loop.pm',
    'lib/UV/Poll.pm',
    'lib/UV/Prepare.pm',
    'lib/UV/Timer.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-can-uv-check.t',
    't/01-can-uv-handle.t',
    't/01-can-uv-idle.t',
    't/01-can-uv-loop.t',
    't/01-can-uv-poll.t',
    't/01-can-uv-prepare.t',
    't/01-can-uv-timer.t',
    't/01-can-uv.t',
    't/01-uv-functions.t',
    't/02-loop-alive.t',
    't/02-loop-close.t',
    't/02-loop-configure.t',
    't/02-loop-time.t',
    't/03-timer-again.t',
    't/03-timer-from-check.t',
    't/03-timer.t',
    't/04-check.t',
    't/05-poll-close.t',
    't/06-idle.t',
    't/07-prepare.t'
);

notabs_ok($_) foreach @files;
done_testing;
