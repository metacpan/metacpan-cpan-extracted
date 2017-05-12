#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::DBI::utils' );
}

diag( "Testing ZConf::DBI::utils $ZConf::DBI::utils::VERSION, Perl $], $^X" );
