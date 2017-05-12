#!/usr/bin/perl -T

use Test::More;

BEGIN {
	use_ok( 'Test::Lithium' );
}

diag( "Testing Test::Lithium $Test::Lithium::VERSION, Perl $], $^X" );
done_testing;
