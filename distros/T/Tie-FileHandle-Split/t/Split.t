use strict;
use warnings;

use Test::More tests=>42;

use lib '../lib';

my @tie_file_handle_split_exported = qw( TIEHANDLE PRINT PRINTF WRITE GETC READ READLINE EOF );

BEGIN {
	use_ok('FileHandle');
	use_ok('File::Temp');
	use_ok('Carp');
	use_ok('Tie::FileHandle::Base');
	use_ok('Tie::FileHandle::Split');
}

can_ok( 'FileHandle', qw ( new ) );
can_ok( 'Tie::FileHandle::Split', @tie_file_handle_split_exported );

my $dir = File::Temp::tempdir( CLEANUP => 1 );
my $split_size = 512;

tie *TEST, 'Tie::FileHandle::Split', $dir, $split_size;

TEST->print( ' ' x ( $split_size - 1 ) ); my @files = (tied *TEST)->get_filenames();
is( scalar @files, 0, 'No files generated when output less than split_size.' );

my $file_created = 0; my $code = sub { $file_created++; };
(tied *TEST)->add_file_creation_listeners( $code, sub {
	#this is called, hopefully, further down when a file is created.
	is( scalar @_, 2, 'Listener called with correct number of arguments.' );
	is( ref $_[0], 'Tie::FileHandle::Split', 'Listener called with Tie::FileHandle::Split as first argument.' );
	is( ref $_[1], '', 'Listener called with scalar as second argument.' );
	ok ( -e $_[1], 'Listener called with an existing filename.' );
	is ( -s $_[1], $split_size, 'Listener called with filename created with correct split_size.' );
} );

is( (tied *TEST)->_get_listeners(), 2, 'Listeners registered from scalars.' );

TEST->print( ' ' x 1 ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 1, 'First file generated at split_size.' );

is( $file_created, 1, 'Creation listener called when file is generated.' );

TEST->print( ' ' x 1 ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 1, 'No extra file 1B after split_size.' );

TEST->print( ' ' x ( $split_size - 2 ) ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 1, 'No extra file at second split_size - 1 split_size.' );

is( $file_created, 1, 'Creation listener not called again before file is created.' );

(tied *TEST)->remove_file_creation_listeners( $code ); $file_created = 0; TEST->print( ' ' x 1 ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 2, 'Second file generated at split_size * 2.' );

is( $file_created, 0, 'Creation listener not called after removing from listeners.' );

(tied *TEST)->write_buffers(); @files = (tied *TEST)->get_filenames();
is( scalar @files, 2, 'No extra file generated when write_buffers is called on a file limit.' );

TEST->print( ' ' x ( $split_size - 1 ) ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 2, 'No extra file generated after write_buffers at split_size - 1.' );

(tied *TEST)->add_file_creation_listeners( [ $code, sub { $file_created++ } , sub { $file_created++ } ] ); (tied *TEST)->remove_file_creation_listeners( $code ); TEST->print( ' ' x 1 ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 3, 'Third file generated after split_size * 3 after a call to write_buffers.' );

is( $file_created, 2, 'Creation listener registered correctly from arryref, unregistered correctly with remove_file_creation_listeners.' );

$file_created = 0; (tied *TEST)->clear_file_creation_listeners(); TEST->print( 'x' x 1 ); (tied *TEST)->write_buffers(); @files = (tied *TEST)->get_filenames();
is( scalar @files, 4, 'Fourth file generated after split_size * 3 + 1 calling write_buffers.' );

is( $file_created, 0, 'Creation listener not called after call to clear_file_creation_listeners.' );

@files = (tied *TEST)->get_filenames();
is( -s $files[scalar @files - 1], 1, 'File generated from write_buffers on partial buffers are of correct size.' );

open( LAST_FILE, '<', $files[scalar @files - 1] ); my $last_file_content = <LAST_FILE>; close ( LAST_FILE );
is( $last_file_content, 'x', 'Check regression where incorrect buffer parts where output to split files.');

(tied *TEST)->add_file_creation_listeners( $code ); TEST->print( '0' x ( $split_size * 2 ) ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 6, 'Fifth and sixth file generated from single print of split_size * 2.' );

is( $file_created, 2, 'Creation listener called twice when 2 files are created.' );

(tied *TEST)->clear_file_creation_listeners();

$split_size = 1024 * 1024; tie *TEST, 'Tie::FileHandle::Split', $dir, $split_size; TEST->print( 'x' x ( 4 * 1024 * 1024 ) ); @files = (tied *TEST)->get_filenames();
is( scalar @files, 4, 'Regresion test! 4 files created for 4MiB with 1MiB split_size in a single print generate 4 files.' );