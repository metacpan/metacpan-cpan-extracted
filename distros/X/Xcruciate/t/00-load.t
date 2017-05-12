#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Xcruciate' );
	use_ok( 'Xcruciate::UnitConfig' );
	use_ok( 'Xcruciate::Utils' );
	use_ok( 'Xcruciate::XcruciateConfig' );
}

diag( "Testing Xcruciate $Xcruciate::VERSION, Perl $], $^X" );
