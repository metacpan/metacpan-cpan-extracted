#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::OCTranspo' );
}

diag( "Testing WebService::OCTranspo $WebService::OCTranspo::VERSION, Perl $], $^X" );
