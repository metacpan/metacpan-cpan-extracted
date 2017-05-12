#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Runner' );
}

diag( "Testing ZConf::Runner $ZConf::Runner::VERSION, Perl $], $^X" );
