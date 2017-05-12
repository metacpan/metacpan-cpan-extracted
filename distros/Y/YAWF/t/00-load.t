#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'YAWF' );
}

diag( "Testing YAWF $YAWF::VERSION, Perl $], $^X" );
