#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
		plan( tests => 2 );
	} else {
		plan( skip_all => 'Not testing on non-Windows' );
	}
}

ok( $] >= 5.006, 'Perl version is new enough' );

use_ok( 'Win32::TieRegistry' );
