#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Win32::Outlook::IAF' );
}

diag( "Testing Win32::Outlook::IAF $Win32::Outlook::IAF::VERSION, Perl $], $^X" );
