#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Weather' );
}

diag( "Testing ZConf::Weather $ZConf::Weather::VERSION, Perl $], $^X" );
