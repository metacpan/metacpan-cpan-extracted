#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::BGSet' );
}

diag( "Testing ZConf::BGSet $ZConf::BGSet::VERSION, Perl $], $^X" );
