#!perl -w

# Copyright 2005..2009 Robert May, All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;

use Win32::GUI 1.02 ();
use Win32::GUI::SplashScreen ();

# Create and diaplay the splash screen
Win32::GUI::SplashScreen::Show(
	-file      => undef,  # explicitly set -file to undef to stop it looking fo default
                          # SPLASH.bmp
	-mintime   => 5,
	-info      => "SplashScreen Demo 2 v1.0",
	-copyright => "(c) 2005..2009 Robert May",
);

# Create the main window
my $mw = Win32::GUI::Window->new(
	-title  => "SplashScreen Demo 2",
	-size   => [700, 500],
) or die "Creating Main Window";

# Hide the splash - blocks until the splashscreen is removed
Win32::GUI::SplashScreen::Done();

# show the main window and enter the dialog phase
$mw->Show();
Win32::GUI::Dialog();
exit(0);
