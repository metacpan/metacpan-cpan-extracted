#!perl -wT
# Check that the module has the public methods that we are expecting
use strict;
use warnings;

use Test::More tests => 1;

use Win32::GUI::SplashScreen;

# Show, Done
can_ok('Win32::GUI::SplashScreen', qw(Show Done) );
