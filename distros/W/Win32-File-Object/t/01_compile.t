#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O ne 'MSWin32' and $ENV{ADAMK_RELEASE} ) {
		# Special magic to get past ADAMK's release automation
		plan( skip_all => "Skipping on ADAMK's release automation" );
	} else {
		plan( tests => 2 );
	}
}

ok ( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'Win32::File::Object' );
