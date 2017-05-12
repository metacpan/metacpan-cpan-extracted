#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'App::HWD' );
	use_ok( 'App::HWD::Task' );
}

diag( "Testing App::HWD $App::HWD::VERSION, Perl $], $^X" );
