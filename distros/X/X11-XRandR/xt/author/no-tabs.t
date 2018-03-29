use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/X11/XRandR.pm',
    'lib/X11/XRandR/Border.pm',
    'lib/X11/XRandR/CurCrtc.pm',
    'lib/X11/XRandR/CurMode.pm',
    'lib/X11/XRandR/Dimension.pm',
    'lib/X11/XRandR/Frequency.pm',
    'lib/X11/XRandR/Geometry.pm',
    'lib/X11/XRandR/Grammar/Monitors.pm',
    'lib/X11/XRandR/Grammar/Verbose.pm',
    'lib/X11/XRandR/Mode.pm',
    'lib/X11/XRandR/Offset.pm',
    'lib/X11/XRandR/Output.pm',
    'lib/X11/XRandR/Property.pm',
    'lib/X11/XRandR/PropertyEDID.pm',
    'lib/X11/XRandR/Receiver/Verbose.pm',
    'lib/X11/XRandR/Screen.pm',
    'lib/X11/XRandR/State.pm',
    'lib/X11/XRandR/Transform.pm',
    'lib/X11/XRandR/Types.pm',
    'lib/X11/XRandR/XRRModeInfo.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

notabs_ok($_) foreach @files;
done_testing;
