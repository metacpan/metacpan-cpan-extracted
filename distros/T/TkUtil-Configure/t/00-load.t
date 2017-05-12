#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TkUtil::Configure' );
}

diag( "Testing TkUtil::Configure $TkUtil::Configure::VERSION, Perl $], $^X" );
