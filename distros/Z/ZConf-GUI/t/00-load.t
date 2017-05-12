#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::GUI' );
}

diag( "Testing ZConf::GUI $ZConf::GUI::VERSION, Perl $], $^X" );
