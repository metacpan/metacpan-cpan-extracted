#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'YAML::LoadURI' );
}

diag( "Testing YAML::LoadURI $YAML::LoadURI::VERSION, Perl $], $^X" );
