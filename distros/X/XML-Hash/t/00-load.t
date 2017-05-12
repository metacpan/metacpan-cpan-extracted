#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Hash' );
}

diag( "Testing XML::Hash $XML::Hash::VERSION, Perl $], $^X" );
