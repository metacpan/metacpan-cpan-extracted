# Copyright 2000-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Track mouse

use strict;
use Win32::OLE;
use Win32::ActAcc;
use Win32::ActAcc::MouseTracker;  


sub main
{
    my $RUN_TIME_SECONDS = 15;

    print "\n"."aaWhereAmI - Track mouse - \n";
    print "Move mouse and watch the running display of the\n";
    print "accessible object under the mouse.\n\n";
    print "For help on the output notation, run aaDigger and use the 'help' and 'abbr' commands.\n\n";

    print "Program will end after $RUN_TIME_SECONDS seconds.\n\n";
    Win32::OLE->Initialize();
    aaTrackMouse($RUN_TIME_SECONDS);
    print "Thank you\n";
}

&main;

