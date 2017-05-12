#!perl -w

# Copyright 2005..2009 Robert May, All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;

use Win32::GUI 1.02 ();
use Win32::GUI::SplashScreen;

# Create and diaplay the splash screen
# Uses default filename of 'SPLASH', and searches for
# SPLASH.bmp and SPLASH.jp[e]g
Win32::GUI::SplashScreen::Show();

# Create the main window
my $mw = Win32::GUI::Window->new(
	-title  => "SplashScreen Demo 1",
	-size   => [700, 500],
) or die "Creating Main Window";

# do some other stuff
sleep(1);

# show the main window and enter the dialog phase
# splash screen taken down after (default) 3 seconds
$mw->Center();
$mw->Show();
Win32::GUI::Dialog();
exit(0);
