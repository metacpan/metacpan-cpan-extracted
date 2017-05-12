#!/usr/bin/env perl

use Test::More tests => 1
	+do { eval { require Test::NoWarnings;Test::NoWarnings->import; 1 } || 0 };

BEGIN {
	use_ok( 'uni::perl' );
}

diag( "Testing uni::perl $uni::perl::VERSION, Perl $], $^X" );
