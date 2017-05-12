#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::template' );
}

diag( "Testing ZConf::template $ZConf::template::VERSION, Perl $], $^X" );
