#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Variable::Lazy' );
}

diag( "Testing Variable::Lazy $Variable::Lazy::VERSION, Perl $], $^X" );
