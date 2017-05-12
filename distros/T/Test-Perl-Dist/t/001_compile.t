#!/usr/bin/perl

use Test::More tests => 2, import => ['!done_testing'];

BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

    ok(($] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
    use_ok( 'Test::Perl::Dist' );
    diag( "Testing Test::Perl::Dist $Test::Perl::Dist::VERSION" );
}


