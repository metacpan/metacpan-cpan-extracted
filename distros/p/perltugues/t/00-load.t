#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'perltugues' );
}

diag( "Testing perltugues $perltugues::VERSION, Perl $], $^X" );
