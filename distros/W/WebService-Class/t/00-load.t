#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Class' );
}

diag( "Testing WebService::Class $WebService::Class::VERSION, Perl $], $^X" );
