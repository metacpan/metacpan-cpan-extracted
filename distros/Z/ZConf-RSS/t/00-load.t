#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::RSS' );
}

diag( "Testing ZConf::RSS $ZConf::RSS::VERSION, Perl $], $^X" );
