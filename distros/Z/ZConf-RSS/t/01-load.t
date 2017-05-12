#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::RSS::GUI' );
}

diag( "Testing ZConf::RSS::GUI $ZConf::RSS::GUI::VERSION, Perl $], $^X" );
