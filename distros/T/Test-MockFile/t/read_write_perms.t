#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/EBADF/;

use Test::MockFile qw< nostrict >;

# READ (sysread) on a write-only handle should fail with EBADF
{
    my $mock = Test::MockFile->file( '/read_ebadf', "hello world" );

    ok( open( my $fh, '>', '/read_ebadf' ), 'open write-only succeeds' );
    my $buf;
    $! = 0;
    my $ret = sysread( $fh, $buf, 10 );
    ok( !defined $ret, 'sysread on write-only handle returns undef' );
    is( $! + 0, EBADF, 'sysread on write-only handle sets EBADF' );
    close $fh;
}

# READ on a read-only handle should succeed
{
    my $mock = Test::MockFile->file( '/read_ok', "hello world" );

    ok( open( my $fh, '<', '/read_ok' ), 'open read-only succeeds' );
    my $buf;
    my $ret = sysread( $fh, $buf, 5 );
    is( $ret, 5,       'sysread on read-only handle returns byte count' );
    is( $buf, 'hello', 'sysread on read-only handle reads data' );
    close $fh;
}

# READ on a read-write handle should succeed
{
    my $mock = Test::MockFile->file( '/read_rw', "hello world" );

    ok( open( my $fh, '+<', '/read_rw' ), 'open read-write succeeds' );
    my $buf;
    my $ret = sysread( $fh, $buf, 5 );
    is( $ret, 5,       'sysread on read-write handle returns byte count' );
    is( $buf, 'hello', 'sysread on read-write handle reads data' );
    close $fh;
}

# Symlink size should equal length of target path
{
    my $link = Test::MockFile->symlink( '/some/target/path', '/test_link_size' );
    my @st = lstat('/test_link_size');
    is( $st[7], length('/some/target/path'), 'symlink lstat size = length of target path' );
}

# Symlink with short target
{
    my $link = Test::MockFile->symlink( '/x', '/test_link_short' );
    my @st = lstat('/test_link_short');
    is( $st[7], 2, 'symlink to /x has size 2' );
}

# Symlink with long target
{
    my $long_target = '/a/very/long/path/to/some/deeply/nested/directory/file.txt';
    my $link = Test::MockFile->symlink( $long_target, '/test_link_long' );
    my @st = lstat('/test_link_long');
    is( $st[7], length($long_target), 'symlink size matches long target path length' );
}

# stat on a symlink follows to the target; lstat returns symlink's own size
{
    my $target = Test::MockFile->file( '/target/file', 'hello world!' );
    my $link   = Test::MockFile->symlink( '/target/file', '/test_link_dash_s' );

    # stat follows the symlink — size should be the target file's content length
    my @st_stat = stat('/test_link_dash_s');
    is( $st_stat[7], 12, 'stat on symlink returns target file size (follows symlink)' );

    # lstat size of the symlink itself = length of target path
    my @st = lstat('/test_link_dash_s');
    is( $st[7], length('/target/file'), 'lstat size of symlink = length of target path' );
}

done_testing();
exit;
