#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ToolSet::y' );
}

diag( "Testing ToolSet::y $ToolSet::y::VERSION, Perl $], $^X" );
