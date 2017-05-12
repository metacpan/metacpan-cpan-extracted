#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::template::GUI' );
}

diag( "Testing ZConf::template::GUI $ZConf::template::GUI::VERSION, Perl $], $^X" );
