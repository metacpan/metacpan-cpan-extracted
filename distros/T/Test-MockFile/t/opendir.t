#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw/tempfile tempdir/;
use File::Basename;

use Errno qw/ENOENT EBADF ENOTDIR/;

use Test::MockFile;    # Everything below this can have its open overridden.

my $temp_dir = tempdir( CLEANUP => 1 );
my ( undef, $filename )    = tempfile( DIR => $temp_dir );
my ( undef, $temp_notdir ) = tempfile();

note "-------------- REAL MODE --------------";
is( -d $temp_dir,                     1, "Temp is created on disk." );
is( opendir( my $dir_fh, $temp_dir ), 1, "$temp_dir can be read" );
my @dir_files;
push @dir_files, scalar readdir($dir_fh);
push @dir_files, scalar readdir($dir_fh);
push @dir_files, scalar readdir($dir_fh);
my $base = basename $filename;
is( [ sort @dir_files ],     [ sort( qw/. .. /, $base ) ], "We read 3 entries in some order. Not predictable, but sort fixes that!" );
is( scalar readdir($dir_fh), undef,                        "undef when nothing left from readdir." );
is( closedir($dir_fh),       1,                            "close the fake dir handle" );

like( warning { readdir($dir_fh) }, qr/^readdir\(\) attempted on invalid dirhandle \S+ /, "warn on readdir when file handle is closed." );

is( opendir( my $bad_fh, "/not/a/valid/path/kdshjfkjd" ), undef,  "opendir on a bad path returns false" );
is( $! + 0,                                               ENOENT, '$! numeric is right.' );

is( opendir( my $notdir_fh, $temp_notdir ), undef,   "opendir on a file returns false" );
is( $! + 0,                                 ENOTDIR, '$! numeric is right.' );

my ( $real_fh, $f3 ) = tempfile( DIR => $temp_dir );
like( warning { readdir($real_fh) }, qr/^readdir\(\) attempted on invalid dirhandle \$fh/, "We only warn if the file handle or glob is invalid." );

note "-------------- MOCK MODE --------------";
my $abc = Test::MockFile->file( "$temp_dir/abc", 'hello' );
my $def = Test::MockFile->file( "$temp_dir/def", 'hello' );
my $bar = Test::MockFile->dir($temp_dir);
my $baz = Test::MockFile->file( $temp_notdir, '' );

is( opendir( $dir_fh, $temp_dir ), 1,     "Mocked temp dir opens and returns true" );
is( scalar readdir($dir_fh),       ".",   "Read .  from fake readdir" );
is( scalar readdir($dir_fh),       "..",  "Read .. from fake readdir" );
is( telldir($dir_fh),              2,     "tell dir in the middle of fake readdir is right." );
is( scalar readdir($dir_fh),       "abc", "Read abc from fake readdir" );
is( scalar readdir($dir_fh),       "def", "Read def from fake readdir" );
is( telldir($dir_fh),              4,     "tell dir at the end of fake readdir is right." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );

is( rewinddir($dir_fh),    1,                  "rewinddir returns true." );
is( telldir($dir_fh),      0,                  "telldir afer rewinddir is right." );
is( [ readdir($dir_fh) ],  [qw/. .. abc def/], "Read the whole dir from fake readdir after rewinddir" );
is( telldir($dir_fh),      4,                  "tell dir at the end of fake readdir is right." );
is( seekdir( $dir_fh, 1 ), 1,                  "seekdir returns where it sought." );
is( [ readdir($dir_fh) ],  [qw/.. abc def/],   "Read the whole dir from fake readdir after seekdir" );
closedir($dir_fh);

is( opendir( my $still_notdir_fh, $temp_notdir ), undef,   "opendir on a mocked file returns false" );
is( $! + 0,                                       ENOTDIR, '$! numeric is right.' );

# Check symlinks appear in readdir
my $dir_for_symlink = Test::MockFile->dir('/foo');
my $dir_in_dir      = Test::MockFile->dir('/foo/infoo');
my $symlink_dest    = Test::MockFile->file( '/foo/dest', '' );
my $symlink         = Test::MockFile->symlink( '/foo/dest', '/foo/source' );

opendir my $sdh, '/foo' or die $!;
my @contents = readdir $sdh;
closedir $sdh or die $!;
is(
    [ sort @contents ],
    [ qw< . .. dest infoo source > ],
    'Symlink and directories appears in directory content'
);

{
    my $d1 = Test::MockFile->dir('/foo2/bar');
    my $d2 = Test::MockFile->dir('/foo2');
    mkdir $d1->path();
    mkdir $d2->path();

    my $f = Test::MockFile->file( '/foo2/bar/baz', '' );

    opendir my $dh, '/foo2' or die $!;
    my @content = readdir $dh;
    closedir $dh or die $!;
    is( \@content, [ qw< . .. bar > ], 'Did not get confused by internal files' );
}

done_testing();
exit;
