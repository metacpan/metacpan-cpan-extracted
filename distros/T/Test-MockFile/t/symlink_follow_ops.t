use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw( ENOENT ELOOP EISDIR );

use Test::MockFile qw< nostrict >;

# Tests that chmod, chown, utime, and truncate follow symlinks
# and operate on the target file, not the symlink itself.

subtest 'chmod follows symlinks' => sub {
    my $file = Test::MockFile->file( '/fake/target', 'data', { mode => 0644 | Test::MockFile::S_IFREG() } );
    my $link = Test::MockFile->symlink( '/fake/target', '/fake/link' );

    is( chmod( 0755, '/fake/link' ), 1, 'chmod via symlink returns 1' );
    is(
        sprintf( '%04o', ( stat '/fake/target' )[2] & 07777 ),
        '0755',
        'target file permissions changed through symlink',
    );
};

subtest 'chmod on broken symlink fails with ENOENT' => sub {
    my $link = Test::MockFile->symlink( '/fake/nowhere', '/fake/broken_chmod' );

    is( chmod( 0755, '/fake/broken_chmod' ), 0, 'chmod on broken symlink returns 0' );
    is( $! + 0, ENOENT, '$! is ENOENT for broken symlink' );
};

subtest 'chmod follows chain of symlinks' => sub {
    my $file  = Test::MockFile->file( '/fake/chain_target', 'data', { mode => 0600 | Test::MockFile::S_IFREG() } );
    my $link1 = Test::MockFile->symlink( '/fake/chain_target', '/fake/chain1' );
    my $link2 = Test::MockFile->symlink( '/fake/chain1', '/fake/chain2' );

    is( chmod( 0700, '/fake/chain2' ), 1, 'chmod through symlink chain returns 1' );
    is(
        sprintf( '%04o', ( stat '/fake/chain_target' )[2] & 07777 ),
        '0700',
        'target file permissions changed through symlink chain',
    );
};

subtest 'chown follows symlinks' => sub {
    my $file = Test::MockFile->file( '/fake/chown_target', 'data' );
    my $link = Test::MockFile->symlink( '/fake/chown_target', '/fake/chown_link' );

    # chown with current user's uid/gid to avoid permission errors
    my $result = chown( $>, $) + 0, '/fake/chown_link' );
    is( $result, 1, 'chown via symlink returns 1' );

    my @stat = stat('/fake/chown_target');
    is( $stat[4], $>, 'target uid set through symlink' );
};

subtest 'chown on broken symlink fails with ENOENT' => sub {
    my $link = Test::MockFile->symlink( '/fake/nowhere', '/fake/broken_chown' );

    my $result = chown( $>, $) + 0, '/fake/broken_chown' );
    is( $result, 0, 'chown on broken symlink returns 0' );
    is( $! + 0, ENOENT, '$! is ENOENT for broken symlink' );
};

subtest 'utime follows symlinks' => sub {
    my $file = Test::MockFile->file( '/fake/utime_target', 'data' );
    my $link = Test::MockFile->symlink( '/fake/utime_target', '/fake/utime_link' );

    my $atime = 1_000_000;
    my $mtime = 2_000_000;

    is( utime( $atime, $mtime, '/fake/utime_link' ), 1, 'utime via symlink returns 1' );

    my @stat = stat('/fake/utime_target');
    is( $stat[8], $atime, 'target atime set through symlink' );
    is( $stat[9], $mtime, 'target mtime set through symlink' );
};

subtest 'utime on broken symlink fails with ENOENT' => sub {
    my $link = Test::MockFile->symlink( '/fake/nowhere', '/fake/broken_utime' );

    is( utime( 100, 200, '/fake/broken_utime' ), 0, 'utime on broken symlink returns 0' );
    is( $! + 0, ENOENT, '$! is ENOENT for broken symlink' );
};

subtest 'utime follows chain of symlinks' => sub {
    my $file  = Test::MockFile->file( '/fake/uchain_target', 'data' );
    my $link1 = Test::MockFile->symlink( '/fake/uchain_target', '/fake/uchain1' );
    my $link2 = Test::MockFile->symlink( '/fake/uchain1', '/fake/uchain2' );

    my $atime = 3_000_000;
    my $mtime = 4_000_000;

    is( utime( $atime, $mtime, '/fake/uchain2' ), 1, 'utime through chain returns 1' );

    my @stat = stat('/fake/uchain_target');
    is( $stat[8], $atime, 'target atime set through symlink chain' );
    is( $stat[9], $mtime, 'target mtime set through symlink chain' );
};

subtest 'truncate follows symlinks (by path)' => sub {
    my $file = Test::MockFile->file( '/fake/trunc_target', 'hello world' );
    my $link = Test::MockFile->symlink( '/fake/trunc_target', '/fake/trunc_link' );

    ok( truncate( '/fake/trunc_link', 5 ), 'truncate via symlink returns true' );
    is( $file->contents(), 'hello', 'target file truncated through symlink' );
};

subtest 'truncate on broken symlink fails with ENOENT' => sub {
    my $link = Test::MockFile->symlink( '/fake/nowhere', '/fake/broken_trunc' );

    ok( !truncate( '/fake/broken_trunc', 0 ), 'truncate on broken symlink returns false' );
    is( $! + 0, ENOENT, '$! is ENOENT for broken symlink' );
};

subtest 'truncate follows symlink to directory fails with EISDIR' => sub {
    my $dir  = Test::MockFile->new_dir('/fake/trunc_dir');
    my $link = Test::MockFile->symlink( '/fake/trunc_dir', '/fake/trunc_dir_link' );

    ok( !truncate( '/fake/trunc_dir_link', 0 ), 'truncate on symlink-to-dir returns false' );
    is( $! + 0, EISDIR, '$! is EISDIR' );
};

subtest 'multiple files with symlinks in chmod' => sub {
    my $file1 = Test::MockFile->file( '/fake/multi1', 'a', { mode => 0600 | Test::MockFile::S_IFREG() } );
    my $file2 = Test::MockFile->file( '/fake/multi2', 'b', { mode => 0600 | Test::MockFile::S_IFREG() } );
    my $link  = Test::MockFile->symlink( '/fake/multi2', '/fake/multi_link' );

    is( chmod( 0755, '/fake/multi1', '/fake/multi_link' ), 2, 'chmod on file + symlink returns 2' );
    is(
        sprintf( '%04o', ( stat '/fake/multi1' )[2] & 07777 ),
        '0755',
        'first file permissions changed',
    );
    is(
        sprintf( '%04o', ( stat '/fake/multi2' )[2] & 07777 ),
        '0755',
        'second file (via symlink) permissions changed',
    );
};

done_testing();
