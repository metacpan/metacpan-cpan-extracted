#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EISDIR EEXIST/;
use File::Temp qw/tempfile tempdir/;

my $temp_dir_name = tempdir( CLEANUP => 1 );
CORE::rmdir $temp_dir_name;

use Test::MockFile qw< nostrict >;

# Proves umask works in this test.
umask 022;

subtest "basic mkdir" => sub {
    $! = 0;
    is( CORE::mkdir($temp_dir_name), 1, "REAL mkdir when dir is missing." );
    is( $! + 0,                      0, ' - $! is unset.' ) or diag "$!";
    is( CORE::rmdir $temp_dir_name,  1, "REAL rmdir when dir is there" );

    my $mock = Test::MockFile->dir($temp_dir_name);

    is( mkdir($temp_dir_name), 1,    "MOCK mkdir when dir is missing." );
    is( $! + 0,                0,    ' - $! is unset.' ) or diag "$!";
    is( $mock->permissions,    0755, "Perms are 0755" );
    ok( -d $temp_dir_name, "-d" );

    is( $! + 0,               0, ' - $! is unset.' ) or diag "$!";
    is( rmdir $temp_dir_name, 1, "MOCK rmdir when dir is there" );
    is( $! + 0,               0, ' - $! is unset.' ) or diag "$!";
    ok( !-d $temp_dir_name, "Directory is not there with -d" );
    ok( !-e $temp_dir_name, "Directory is not there with -e" );
};

subtest "undef dir name" => sub {
    my $return;

    $! = 0;
    like( warning { $return = CORE::mkdir(undef) }, qr/^Use of uninitialized value in mkdir at.+\n$/, "REAL mkdir when undef is passed as the file name." );
    is( $! + 0,  ENOENT, ' - $! is ENOENT.' ) or diag "\$\! = $!";
    is( $return, 0,      " - Returns 0" );

    $! = 0;
    like( warning { $return = mkdir(undef) }, qr/^Use of uninitialized value in mkdir at.+\n$/, "MOCK mkdir when undef is passed as the file name." );
    is( $! + 0,  ENOENT, ' - $! is ENOENT.' ) or diag "\$\! = $!";
    is( $return, 0,      " - Returns 0" );

};

subtest "REAL mkdir" => sub {
    $! = 0;
    is( CORE::mkdir($temp_dir_name), 1, "put the real tempdir back" );
    is( mkdir("$temp_dir_name/a"),   1, "A real mkdir through the shim" );
    is( $! + 0,                      0, ' - $! is unset.' ) or diag "\$\! = $!";

    is( mkdir("$temp_dir_name/a"), 0,      "A real mkdir through the shim when it exists already" );
    is( $! + 0,                    EEXIST, ' - $! is EEXIST.' ) or diag "\$\! = $!";

    # Cleanup.
    rmdir "$temp_dir_name/a";
};

subtest "mkdir when file exists" => sub {
    my $file_path = "$temp_dir_name/a";
    CORE::mkdir $temp_dir_name;
    touch($file_path);

    $! = 0;
    is( CORE::mkdir($file_path), 0,      "A real mkdir when the dir is already a file." );
    is( $! + 0,                  EEXIST, ' - $! is EEXIST.' ) or diag "\$\! = $!";

    my $mock = Test::MockFile->file( $file_path, "" );

    $! = 0;
    is( mkdir($file_path), 0,      "A mock mkdir when the dir is already a file." );
    is( $! + 0,            EEXIST, ' - $! is EEXIST.' ) or diag "\$\! = $!";

    $mock->unlink;
    is( mkdir($file_path), 1, "A mock mkdir when the path is a mocked file but not on disk becomes a directory mock." );
    is( $mock->is_dir,     1, '$mock is now a directory' );

};

subtest "mkdir when symlink exists" => sub {
    my $file_path = "$temp_dir_name/a";
    CORE::mkdir $temp_dir_name;
    CORE::symlink( "$temp_dir_name/ab", $file_path );

    $! = 0;
    is( CORE::mkdir($file_path), 0,      "A real mkdir when the dir is already a symlink." );
    is( $! + 0,                  EEXIST, ' - $! is EEXIST.' ) or diag "\$\! = $!";
    CORE::unlink($file_path);

    my $mock = Test::MockFile->symlink( "${file_path}b", $file_path );

    $! = 0;
    is( mkdir($file_path), 0,      "A mock mkdir when the dir is already a symlink." );
    is( $! + 0,            EEXIST, ' - $! is EEXIST.' ) or diag "\$\! = $!";

    # Stop mocking this and start over
    undef $mock;
    $mock = Test::MockFile->dir($file_path);

    is( mkdir($file_path), 1, "A mock mkdir when the path is a mocked symlink but not on disk turns the mock object into a dir." );
    is( $mock->is_dir,     1, '$mock is now a directory' );
};

subtest "mkdir with file perms" => sub {
    CORE::mkdir $temp_dir_name;
    my $file_path = "$temp_dir_name/a";

    umask(0);
    $! = 0;
    is( CORE::mkdir( $file_path, 0770 ), 1, "A real mkdir with 0770 perms." );
    is( $! + 0,                          0, ' - $! is unset.' ) or diag "\$\! = $!";
    my @stats = CORE::stat($file_path);
    is( $stats[2], 040770, "permissions are the real file's permissions" );

    my $mock = Test::MockFile->dir($file_path);

    $! = 0;
    is( mkdir( $file_path, 0700 ), 1,    "A mock mkdir with 0700 perms." );
    is( $! + 0,                    0,    ' - $! is unset.' ) or diag "\$\! = $!";
    is( $mock->permissions,        0700, "Permissions are the mock permissions of 0700" );

    umask(022);
    is( rmdir($file_path),         1,    "Remove the fake dir" );
    is( mkdir( $file_path, 0777 ), 1,    "A mock mkdir with 0700 perms." );
    is( $! + 0,                    0,    ' - $! is unset.' ) or diag "\$\! = $!";
    is( $mock->permissions,        0755, "Permissions get umask applied." );

};

done_testing();

sub touch {
    my $path = shift or die;

    CORE::open( my $fh, '>>', $path ) or die;
    print $fh '';
    close $fh;

    return 1;
}
