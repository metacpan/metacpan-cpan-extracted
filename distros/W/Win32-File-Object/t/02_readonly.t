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
		plan( tests => 12 );
	}
}

use File::Spec::Functions ':ALL';
use File::Remove          ();
use Win32::File::Object   ();

# Test file name
my $path = catfile(qw{ t readonly.txt });
File::Remove::remove( \1, $path ) if -e $path;
ok ( ! -e $path, 'The test file does not exist' );
END {
	File::Remove::remove( \1, $path ) if -e $path;
}





#####################################################################
# Basic Test

# Create a file
open( FILE, '>', $path ) or die "open: $!";
print FILE "This is a temporary test file\n";
close( FILE ) or die "close: $!";
ok( -f $path, 'Created file ok' );

SCOPE: {
	# Readonly should be false
	my $file = Win32::File::Object->new( $path );
	isa_ok( $file, 'Win32::File::Object' );
	is( $file->readonly, 0, '->readonly is false' );

	# Set readonly to true
	is( $file->readonly(2), 1, 'Set readonly ok' );
	is( Win32::File::Object->new($path)->readonly, 0, '->readonly(true) does not autowrite' );

	# Write the file
	is( $file->write, 1, '->write ok' );
	is( Win32::File::Object->new($path)->readonly, 1, '->write worked' );
}





#####################################################################
# Autowrite Test

SCOPE: {
	# Readonly should be true
	my $file = Win32::File::Object->new( $path, 1 );
	isa_ok( $file, 'Win32::File::Object' );
	is( $file->readonly, 1, '->readonly is false' );

	# Set readonly to true
	is( $file->readonly(undef), 0, 'Set readonly ok' );
	is( Win32::File::Object->new($path)->readonly, 0, '->readonly(false) does autowrite' );
}
