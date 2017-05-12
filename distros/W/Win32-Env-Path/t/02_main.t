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
		plan( tests => 6 );
	}
}

use Win32::Env::Path;





#####################################################################
# Object Creation

SCOPE: {
	my $path = Win32::Env::Path->new;
	isa_ok( $path, 'Win32::Env::Path' );
	is( $path->name, 'PATH', '->name ok' );
	is( $path->autosave, 1, '->autosave is true by default' );
	is( $path->user,   ! 1, '->user is false by default' );
	ok( defined($path->value), '->string exists' );
	is( ref($path->array), 'ARRAY', '->array exists' );

	# Check the real path of something
	my $spec = $path->resolve( $path->array->[0] );

	# Clean the path
	$path->clean;
}
