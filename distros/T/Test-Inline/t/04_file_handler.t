#!/usr/bin/perl

# Test as much of Test::Inline::IO::File as we can without having
# to actually write to disk. We might deal with the last ->write method
# another time

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	require FindBin;
	$FindBin::Bin = $FindBin::Bin;
}

use File::Spec::Functions ':ALL';
use Test::More tests => 13;
use Test::Inline ();

# Prepare
$| = 1;
my $libdir = $ENV{HARNESS_ACTIVE} ? 'lib'
	: catdir($FindBin::Bin, updir(), 'lib');
ok( -d $libdir, 'Found the distribution lib directory' );
my $inline2 = catfile('Test', 'Inline.pm');
my $inline3 = catfile('Test', 'Inline3.pm');





#####################################################################
# Test::Inline::IO::File Tests

# Create a new FileHandler
my $File = Test::Inline::IO::File->new( $libdir );
isa_ok( $File, 'Test::Inline::IO::File' );

# The file for the main Test::Inline file MUST exist
ok( $File->exists_file( $inline2 ), '->exists returns true for a file that exists' );

# On the other hand, there isn't a Test::Inline3 module
ok( ! $File->exists_file( $inline3 ), '->exists return false for a file that does not exist' );

# Read the contents of Test::Inline and check the file length
my $source = $File->read( $inline2 );
ok( ref $source eq 'SCALAR', '->read returns a SCALAR reference' );
ok( length $$source > 10000, '->read returns a string that is long enough' );
ok( length $$source < 25000, '->read returns a string that is not TOO long' );

# Read of a bad file returns undef
is( $File->read( $inline3 ), undef, '->read of a bad file returns undef' );

# Check good and bad ->file calls
is_deeply( $File->class_file( 'Test::Inline' ), [ $inline2 ], '->file with an existing class returns correctly' );
is( $File->class_file( 'Test::Inline3' ), '', '->file with a bad class returns false' );

# Check good and bad ->find calls
is_deeply( $File->find( 'Test/Inline' ), [
	catfile( 'Test', 'Inline', 'Content.pm'            ),
	catfile( 'Test', 'Inline', 'Content', 'Default.pm' ),
	catfile( 'Test', 'Inline', 'Content', 'Legacy.pm'  ),
	catfile( 'Test', 'Inline', 'Content', 'Simple.pm'  ),
	catfile( 'Test', 'Inline', 'Extract.pm'            ),
	catfile( 'Test', 'Inline', 'IO', 'File.pm'         ),
	catfile( 'Test', 'Inline', 'Script.pm'             ),
	catfile( 'Test', 'Inline', 'Section.pm'            ),
	catfile( 'Test', 'Inline', 'Util.pm'               ),
	], '->find with path returns everything below it' );
is_deeply( $File->find( 'Test/Inline/IO' ), [
	catfile( 'Test', 'Inline', 'IO', 'File.pm'    ),
	], '->find with path returns everything below it' );
is( $File->find( 'Test/Inline3' ), undef, '->find with a dir returns undef' );

1;
