#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Win32::WindowsMedia' );
}

diag( "Testing Win32::WindowsMedia $Win32::WindowsMedia::VERSION, Perl $], $^X" );
