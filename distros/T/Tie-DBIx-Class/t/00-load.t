#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::DBIx::Class' );
}

diag( "Testing Tie::DBIx::Class $Tie::DBIx::Class::VERSION, Perl $], $^X" );
