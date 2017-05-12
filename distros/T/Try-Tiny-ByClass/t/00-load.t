#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Try::Tiny::ByClass' );
}

diag( "Testing Try::Tiny::ByClass $Try::Tiny::ByClass::VERSION, Perl $], $^X" );
