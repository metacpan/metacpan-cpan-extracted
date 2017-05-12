#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::Runner::GUI' );
}

diag( "Testing ZConf::Runner::GUI $ZConf::Runner::GUI::VERSION, Perl $], $^X" );
