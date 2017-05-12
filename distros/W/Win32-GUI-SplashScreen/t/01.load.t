#!perl -wT
# Check that the module loads stand-alone
use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Win32::GUI::SplashScreen' );

diag( "Testing Win32::GUI::SplashScreen $Win32::GUI::SplashScreen::VERSION" );
