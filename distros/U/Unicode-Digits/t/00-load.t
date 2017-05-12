#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Unicode::Digits' );
}

diag( "Testing Unicode::Digits $Unicode::Digits::VERSION, Perl $], $^X" );
