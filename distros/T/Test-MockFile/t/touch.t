#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EISDIR EPERM/;

use File::Temp qw/tempfile tempdir/;

note "-------------- REAL MODE --------------";
my $temp_dir = tempdir( CLEANUP => 1 );
$! = 0;
is( unlink($temp_dir), 0, "unlink on a dir fails" );
my $unlink_dir_errorno = $! + 0;

use Test::MockFile ();

note "-------------- MOCK MODE --------------";
my @mock;
my $file = Test::MockFile->file( '/file', "" );
my $dir = Test::MockFile->dir( '/dir', [] );
my $link = Test::MockFile->symlink( '/link', '/tonowhere' );

is( $link->unlink, 1, "unlink /link works." );
is( $link->exists, 0, "/link is now gone" );
{
    local $!;
    is( $dir->unlink, 0, "unlink /dir doesn't work." );
    is( $! + 0, $unlink_dir_errorno, "   ... and throws a \$\!" );
}

like( dies { $dir->touch },  qr/^touch only supports files at \S/, "touch /dir doesn't work." );
like( dies { $link->touch }, qr/^touch only supports files at \S/, "touch /link doesn't work." );

is( $file->mtime(5), 5, "Set mtime to 1970" );
is( $file->ctime(5), 5, "Set ctime to 1970" );
is( $file->atime(5), 5, "Set atime to 1970" );

my $now = time;
is( $file->touch, 1, "Touch a missing file." );
ok( $file->mtime >= $now, "mtime is set." ) or diag $file->mtime;
ok( $file->ctime >= $now, "ctime is set." ) or diag $file->ctime;
ok( $file->atime >= $now, "atime is set." ) or diag $file->atime;

ok( -e "/file", "/file exists with -e" );

is( $file->unlink,   1,     "/file is removed via unlink method" );
is( $file->contents, undef, "/file is missing via contents check" );
is( $file->size,     undef, "/file is missing via size method" );
ok( !-e "/file", "/file is removed via -e check" );

is( $file->contents("ABC"), "ABC", "Set file to have stuff in it." );
is( $file->touch(1234),     1,     "Touch an existing file." );
is( $file->mtime, 1234, "mtime is set to 1234." ) or diag $file->mtime;
is( $file->ctime, 1234, "ctime is set to 1234." ) or diag $file->ctime;
is( $file->atime, 1234, "atime is set to 1234." ) or diag $file->atime;

done_testing();
exit;
