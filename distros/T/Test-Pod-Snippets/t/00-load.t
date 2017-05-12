#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Pod::Snippets' );
}

diag( "Testing Test::Pod::Snippets $Test::Pod::Snippets::VERSION, Perl $], $^X" );
