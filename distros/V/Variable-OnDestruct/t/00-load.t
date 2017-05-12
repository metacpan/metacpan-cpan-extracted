#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Variable::OnDestruct' );
}

diag( "Testing Variable::OnDestruct $Variable::OnDestruct::VERSION, Perl $], $^X" );
