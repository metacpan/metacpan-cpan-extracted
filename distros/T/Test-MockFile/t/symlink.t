#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Errno qw( ENOENT EEXIST );
use Test::MockFile;

my $dir  = Test::MockFile->dir('/foo');
my $file = Test::MockFile->file('/bar');
ok( !-d ('/foo'), 'Directory does not exist yet' );

my $symlink = Test::MockFile->symlink( '/bar', '/foo/baz' );
ok( -d ('/foo'), 'Directory now exists' );

{
    opendir my $dh, '/foo' or die $!;
    my @content = readdir $dh;
    closedir $dh or die $!;
    is(
        \@content,
        [qw< . .. baz >],
        'Directory with symlink content are correct',
    );
}

undef $symlink;

{
    opendir my $dh, '/foo' or die $!;
    my @content = readdir $dh;
    closedir $dh or die $!;
    is(
        \@content,
        [qw< . .. >],
        'Directory no longer has symlink',
    );
}

# --- stat/lstat on unlinked symlinks ---
{
    my $target = Test::MockFile->file( '/tmp/stat_target', 'data' );
    my $link   = Test::MockFile->symlink( '/tmp/stat_target', '/tmp/stat_link' );

    # Before unlink: lstat on symlink should succeed
    my @lstat_before = lstat('/tmp/stat_link');
    ok( scalar @lstat_before, 'lstat on live symlink returns stat data' );

    # Unlink the symlink
    ok( unlink('/tmp/stat_link'), 'unlink symlink succeeds' );

    # After unlink: lstat should fail with ENOENT
    my @lstat_after = lstat('/tmp/stat_link');
    is( scalar @lstat_after, 0, 'lstat on unlinked symlink returns empty list' );
    is( $! + 0, ENOENT, 'lstat on unlinked symlink sets ENOENT' );

    # stat should also fail
    my @stat_after = stat('/tmp/stat_link');
    is( scalar @stat_after, 0, 'stat on unlinked symlink returns empty list' );
}

# --- symlink() builtin sets creation timestamps ---
{
    note "symlink() sets atime, mtime, ctime on the new symlink";
    my $target = Test::MockFile->file( '/mock/ts_target', 'data' );
    my $link_mock = Test::MockFile->file('/mock/ts_link');

    # Set mock timestamps to a known past value
    $link_mock->{'atime'} = 1000;
    $link_mock->{'mtime'} = 1000;
    $link_mock->{'ctime'} = 1000;

    my $before = time;
    symlink( '/mock/ts_target', '/mock/ts_link' );

    my @lstat = lstat('/mock/ts_link');
    ok( scalar @lstat, 'lstat on new symlink succeeds' );
    ok( $lstat[8] >= $before,  'symlink atime set to current time' );
    ok( $lstat[9] >= $before,  'symlink mtime set to current time' );
    ok( $lstat[10] >= $before, 'symlink ctime set to current time' );
}

# --- symlink() on existing target returns EEXIST ---
{
    note "symlink() on existing path returns EEXIST";
    my $target = Test::MockFile->file( '/mock/eexist_target', 'data' );
    my $existing = Test::MockFile->file( '/mock/eexist_link', 'already here' );

    my $result = symlink( '/mock/eexist_target', '/mock/eexist_link' );
    is( $result, 0, 'symlink on existing file returns 0' );
    is( $! + 0, EEXIST, 'symlink on existing file sets EEXIST' );
}

done_testing();
exit 0;
