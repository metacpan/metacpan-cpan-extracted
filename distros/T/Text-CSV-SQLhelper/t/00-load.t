#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::CSV::SQLhelper' );
}

diag( "Testing Text::CSV::SQLhelper $Text::CSV::SQLhelper::VERSION, Perl $], $^X" );
