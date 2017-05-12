#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Harness::FileFilter' );
}

diag( "Testing Test::Harness::FileFilter $Test::Harness::FileFilter::VERSION, Perl $], $^X" );
