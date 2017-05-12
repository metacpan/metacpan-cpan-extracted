#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Gravatar' );
}

diag( "Testing WebService::Gravatar $WebService::Gravatar::VERSION, Perl $], $^X" );
