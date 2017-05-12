#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O ne 'MSWin32' ) {
		# Special magic to get past ADAMK's release automation
		plan( skip_all => "Skipping on ADAMK's release automation" );
	} else {
		plan( tests => 3 );
	}
}
use Test::Script;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Win32::Env::Path' );

script_compiles_ok( 'script/win32envpath' );
