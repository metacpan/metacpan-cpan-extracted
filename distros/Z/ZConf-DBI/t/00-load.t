#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::DBI' );
}

diag( "Testing ZConf::DBI $ZConf::DBI::VERSION, Perl $], $^X" );
