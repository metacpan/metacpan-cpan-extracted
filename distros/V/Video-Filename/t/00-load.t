#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Video::Filename' );
}

diag( "Testing Video::Filename $Video::Filename::VERSION, Perl $], $^X" );
