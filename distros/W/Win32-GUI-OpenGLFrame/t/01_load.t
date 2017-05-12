#!perl -wT
use strict;
use warnings;

use Test::More (tests => 3);

# Pre-requisites: Check that we're on windows or cygwin
# bail out if we're not
if ( not ($^O =~ /MSwin32|cygwin/i)) {
    diag("\nWin32::GUI::OpenGLFrame can only run on MSWin32 or cygwin, not '$^O'");
    print "Bail out! Incompatible Operating System\n";
}
pass("Correct OS: $^O");
    
# Check that Win32::GUI::OpenGLFrame loads, and bail out of all
# tests if it doesn't
use_ok('Win32::GUI::OpenGLFrame') or
    print "Bail out! Failed to load.\n";

# Check that we have a version
ok($Win32::GUI::OpenGLFrame::VERSION, 'Has a version');
