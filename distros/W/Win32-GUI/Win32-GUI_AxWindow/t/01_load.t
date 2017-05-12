#!perl -wT
# Win32::GUI::AxWindow test suite
# $Id: 01_load.t,v 1.1 2006/06/11 15:47:21 robertemay Exp $
#
# - check pre-requsites
# - check module loads
# - check module has a version

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# Pre-requisites: Bail out if we havent got Test::More
eval "use Test::More";
if($@) {
    # As we haven't got Test::More, can't use diag()
    print "#\n# Test::More required to perform any Win32::GUI::Grid test\n";
    chomp $@;
    $@ =~ s/^/# /gm;
    print "$@\n";
    print "Bail Out! Test::More not available\n";
    exit(1);
}

plan( tests => 3 );

# Pre-requisites: Check that we're on windows or cygwin
# bail out if we're not
if ( not ($^O =~ /MSwin32|cygwin/i)) {
    diag("\nWin32::GUI::DIBitmap can only run on MSWin32 or cygwin, not '$^O'");
    print "Bail out! Incompatible Operating System\n";
}
pass("Correct OS: $^O");
    
# Check that Win32::GUI::AxWindow loads, and bail out of all
# tests if it doesn't
use_ok('Win32::GUI::AxWindow')
  or print STDOUT "Bail out! Can't load Win32::GUI::AxWindow";

# Check that Win32::GUI::AxWindow has a version
ok(defined $Win32::GUI::AxWindow::VERSION, "Win32::GUI::AxWindow version check");
