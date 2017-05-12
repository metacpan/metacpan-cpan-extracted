#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Mail' );
}

diag( "Testing ZConf::Mail $ZConf::Mail::VERSION, Perl $], $^X" );
