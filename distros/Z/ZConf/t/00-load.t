#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf' );
}

diag( "Testing ZConf $ZConf::VERSION, Perl $], $^X" );
