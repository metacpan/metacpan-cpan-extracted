#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ZConf::backends::file' );
}

diag( "Testing ZConf::backends::file $ZConf::backends::file::VERSION, Perl $], $^X" );
