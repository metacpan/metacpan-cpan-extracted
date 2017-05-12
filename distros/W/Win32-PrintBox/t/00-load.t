#!perl -T

use Test::More tests => 1;

BEGIN {
		
	print STDERR "pause_in overridden for testing";
	use_ok( 'Win32::PrintBox' ) || print "Bail out!\n";
}
sub Win32::PrintBox::pause_in {};

diag( "Testing Win32::PrintBox $Win32::PrintBox::VERSION, Perl $], $^X" );
