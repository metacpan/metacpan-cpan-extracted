# This implements all test cases mentioned in SYNOPSIS.
# To make it runnable, the following changes have been done:
#   - Test::Expander used instead of Path::Tiny (this includes both Path::Tiny and Test2::V0).
#   - $PATH referring to a temporary directory used instead of path( 'path' ).
#   - The necessary directory structure and test files creation implemented.

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};
use Test::Files;

use Archive::Zip          qw( :ERROR_CODES );
use File::Copy::Recursive qw( dircopy );

const my $PATH => path( $TEMP_DIR );

my $got_file       = $PATH->child( qw( got file ) );
my $reference_file = $PATH->child( qw( reference file ) );
my $got_dir        = $PATH->child( qw( got dir ) );
my $reference_dir  = $PATH->child( qw( reference dir with some stuff ) );
my @file_list      = qw( expected file );
my ( $content_check, $expected, $filter, $options );

plan( 24 );

# Simply compares file contents to a string:
$expected = "contents\nof file";
$got_file->parent->mkdir;
$got_file->spew( $expected );
file_ok( $got_file, $expected, 'got file has expected contents' );

# Two identical variants comparing file contests to a string ignoring differences in time stamps:
$expected = "filtered contents\nof file\ncreated at 00:00:00";
$got_file->spew( $expected =~ s/00:00:00/12:34:56/r );
$filter   = sub { shift =~ s{ \b (?: [01] \d | 2 [0-3] ) : (?: [0-5] \d ) : (?: [0-5] \d ) \b }{00:00:00}grx };
$options  = { FILTER => $filter };
file_ok       ( $got_file, $expected, $options, "'$got_file' has contents expected after filtering" );
file_filter_ok( $got_file, $expected, $filter,  "'$got_file' has contents expected after filtering" );

# Simply compares two file contents:
$reference_file->parent->mkdir;
$got_file->copy( $reference_file );
compare_ok( $got_file, $reference_file, 'files are the same' );

# Two identical variants comparing contents of two files ignoring differences in time stamps:
$got_file->spew( $expected );
$filter   = sub { shift =~ s{ \b (?: [01] \d | 2 [0-3] ) : (?: [0-5] \d ) : (?: [0-5] \d ) \b }{00:00:00}grx };
$options = { FILTER => $filter };
compare_ok       ( $got_file, $reference_file, $options, 'files are almost the same' );
compare_filter_ok( $got_file, $reference_file, $filter,  'files are almost the same' );

# Verifies if both got file and reference file exist:
$options = { EXISTENCE_ONLY => 1 };
compare_ok( $got_file, $reference_file, $options, 'both files exist' );

# Verifies if got file and reference file have identical size:
$options = { SIZE_ONLY => 1 };
compare_ok( $got_file, $reference_file, $options, 'both files have identical size' );

# Verifies if the directory has all expected files (not recursively!):
$expected = [ qw( files got_dir must contain ) ];
$got_dir->child( 'subdir' )->mkdir;
$got_dir->child( $_ )->touch foreach @$expected, 'additional_file';
$got_dir->child( 'subdir' )->child( 'file_in_subdir' )->touch;
dir_contains_ok( $got_dir, $expected, 'directory has all files in list' );

# Two identical variants doing the same verification as before,
# but additionally verifying if the directory has nothing but the expected files (not recursively!):
$options = { SYMMETRIC => 1 };
$got_dir->child( 'additional_file' )->remove;
dir_contains_ok     ( $got_dir, $expected, $options, 'directory has exactly the files in the list' );
dir_only_contains_ok( $got_dir, $expected,           'directory has exactly the files in the list' );

# The same as before, but recursive:
$options = { RECURSIVE => 1, SYMMETRIC => 1 };
$expected = [ @$expected, 'subdir/file_in_subdir' ];
dir_contains_ok( $got_dir, $expected, $options, 'directory and its subdirectories have exactly the files in the list' );

# The same as before, but ignoring files, which names do not match the required pattern (file "must" will be skipped):
$options = { NAME_PATTERN => '^[cfg]', RECURSIVE => 1, SYMMETRIC => 1 };
$got_dir->child( 'must' )->remove;
dir_contains_ok(
  $got_dir, $expected, $options,
  "directory and its subdirectories have exactly the files in the list except of file 'must'"
);

# Compares two directories by comparing file contents (not recursively!):
dircopy( $got_dir, $reference_dir );
$reference_dir->child( 'subdir' )->remove_tree;
compare_dirs_ok(
  $got_dir, $reference_dir,
  "all files from '$got_dir' are the same in '$reference_dir' (same names, same contents), subdirs are skipped"
);

# The same as before, but subdirectories are considered, too:
dircopy( $got_dir, $reference_dir );
$options = { RECURSIVE => 1 };
compare_dirs_ok(
  $got_dir, $reference_dir, $options, "all files from '$got_dir' and its subdirs are the same in '$reference_dir'"
);

# The same as before, but only file sizes are compared:
$got_dir      ->child( 'contain' )->spew( 'abc' );
$reference_dir->child( 'contain' )->spew( 'xyz' );
$options = { RECURSIVE => 1, SIZE_ONLY => 1 };
compare_dirs_ok(
  $got_dir, $reference_dir, $options, "all files from '$got_dir' and its subdirs have same sizes in '$reference_dir'"
);

# The same as before, but only file existence is verified:
$reference_dir->child( 'contain' )->spew( 'some longer text' );
$options = { EXISTENCE_ONLY => 1, RECURSIVE => 1 };
compare_dirs_ok(
  $got_dir, $reference_dir, $options, "all files from '$got_dir' and its subdirs exist in '$reference_dir'"
);

# The same as before, but only files with base names starting with 'A' are considered:
$got_dir      ->child( 'contain' )->remove;
$got_dir      ->child( 'A.txt' )->touch;
$reference_dir->child( 'A.txt' )->touch;
$reference_dir->child( qw( subdir A.txt ) )->touch;
$options = { EXISTENCE_ONLY => 1, NAME_PATTERN => '^A', RECURSIVE => 1 };
compare_dirs_ok(
  $got_dir, $reference_dir, $options,
  "all files from '$got_dir' and its subdirs with base names starting with 'A' exist in '$reference_dir'"
);

# The same as before, but the symmetric verification is requested:
$got_dir->child( qw( subdir A.txt ) )->touch;
$options = { EXISTENCE_ONLY => 1, NAME_PATTERN => '^A', RECURSIVE => 1, SYMMETRIC => 1 };
compare_dirs_ok(
  $got_dir, $reference_dir, $options,
  "all files from '$got_dir' and its subdirs with base names starting with 'A' exist in '$reference_dir' and vice versa"
);

# Two identical version of comparison of two directories by file contents,
# whereas these contents are first filtered so that time stamps in form of 'HH:MM:SS' are replaced by '00:00:00'
# like in examples for file_filter_ok and compare_filter_ok:
dircopy( $reference_dir, $got_dir );
$expected = "filtered contents\nof file\ncreated at 00:00:00";
$got_dir      ->child( 'A.txt' )->spew( $expected =~ s/00:00:00/12:34:56/r );
$reference_dir->child( 'A.txt' )->spew( $expected =~ s/00:00:00/21:43:05/r );
$filter   = sub { shift =~ s{ \b (?: [01] \d | 2 [0-3] ) : (?: [0-5] \d ) : (?: [0-5] \d ) \b }{00:00:00}grx };
$options = { FILTER => $filter };
compare_dirs_ok(
  $got_dir, $reference_dir, $options,
  "all files from '$got_dir' are the same in '$reference_dir', subdirs are skipped, differences of time stamps ignored"
);
compare_dirs_filter_ok(
  $got_dir, $reference_dir, $filter,
  "all files from '$got_dir' are the same in '$reference_dir', subdirs are skipped, differences of time stamps ignored"
);

# Verifies if all plain files in directory and its subdirectories contain the word 'good'
# (take into consideration the -f test below excluding special files from comparison!):
$got_dir->visit( sub { $_->spew( 'This is a good plain file!' ) unless $_->is_dir }, { recurse => 1 } );
$content_check = sub { my ( $file ) = @_; not -f $file or path( $file )->slurp =~ / \b good \b /x };
$options       = { RECURSIVE => 1 };
find_ok( $got_dir, $content_check, $options, "all files from '$got_dir' and subdirectories contain the word 'good'" );

# Compares PKZIP archives considering both global and file comments.
# Both archives contain the same members in different order:
my @fileNos = ( 0, 1 );
foreach my $archive ( $got_file, $reference_file ) {
  my $zip = Archive::Zip->new();
  $zip->zipfileComment( 'Global comment' );
  $zip->addString( "This is file No. $_", "file_$_" )->fileComment( "Some comment to file No. $_" ) foreach @fileNos;
  bail_out( "Cannot create '$archive.zip'" ) if $zip->writeToFileNamed( "$archive.zip" ) != AZ_OK;
  @fileNos = reverse( @fileNos );
}
my $extract = sub {
  my ( $file ) = @_;
  my $zip = Archive::Zip->new();
  die( "Cannot read '$file'" ) if $zip->read( $file ) != AZ_OK;
  die( "Cannot extract from '$file'" ) if $zip->extractTree != AZ_OK;
};
my $meta_data = sub {
  my ( $file ) = @_;
  my $zip = Archive::Zip->new();
  die( "Cannot read '$file'" ) if $zip->read( $file ) != AZ_OK;
  my %meta_data = ( '' => $zip->zipfileComment );
  $meta_data{ $_->fileName } = $_->fileComment foreach $zip->members;
  return \%meta_data;
};
my $got_compressed_content       = path( "$got_file.zip"       )->slurp;
my $reference_compressed_content = path( "$reference_file.zip" )->slurp;
ok(
  $got_compressed_content ne $reference_compressed_content,
  "'$got_file.zip' and '$reference_file.zip' are physically different, but"
);
compare_archives_ok(
  "$got_file.zip", "$reference_file.zip", { EXTRACT => $extract, META_DATA => $meta_data },
  "'$got_file.zip' and '$reference_file.zip' are logically identical"
);
