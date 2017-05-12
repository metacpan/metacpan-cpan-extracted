#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Win32::Env' );
}

diag( "Testing Win32::Env $Win32::Env::VERSION, Perl $], $^X" );
