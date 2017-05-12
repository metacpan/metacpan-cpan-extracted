#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Win32::HostExplorer' );
}

diag( "Testing Win32::HostExplorer $Win32::HostExplorer::VERSION, Perl $], $^X" );
