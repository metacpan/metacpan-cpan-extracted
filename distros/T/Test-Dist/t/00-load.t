#!/usr/bin/env perl

use Test::NoWarnings;
use Test::More tests => 2;

BEGIN {
	use_ok( 'Test::Dist' );
}

diag( "Testing Test::Dist $Test::Dist::VERSION, Perl $], $^X" );
