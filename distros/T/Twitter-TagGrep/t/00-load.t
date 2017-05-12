#!/usr/bin/perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Twitter::TagGrep' );
}

diag( "Testing Twitter::TagGrep $Twitter::TagGrep::VERSION, Perl $], $^X" );
