#!perl -w
BEGIN {
	print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
	$| = 1;
}

# $Id: 04_std.t,v 1.2 2008/10/01 11:10:12 int32 Exp $

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest qw/
    GetDesktopWindow
    IsWindow
    /;

# Standard Check
ok(IsWindow(GetDesktopWindow()));
