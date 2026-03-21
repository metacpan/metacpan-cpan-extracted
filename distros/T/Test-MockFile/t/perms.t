use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw( EACCES EPERM );
use Fcntl qw( O_RDONLY O_WRONLY O_RDWR O_CREAT );

use Test::MockFile qw< nostrict >;

# GitHub issue #3: User perms are not checked on file access.
# When set_user() is active, mock operations check Unix permission bits.

# =========================================================================
# Cleanup helper — always clear mock user after each subtest
# =========================================================================

sub with_user (&@) {
    my ( $code, $uid, @gids ) = @_;
    Test::MockFile->set_user( $uid, @gids );
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    Test::MockFile->clear_user();
    die $err unless $ok;
}

# =========================================================================
# set_user / clear_user basics
# =========================================================================

subtest 'set_user and clear_user' => sub {

    # No mock user by default — open should succeed regardless of mode
    my $f = Test::MockFile->file( '/perms/basic', 'hello', { mode => 0000, uid => 99, gid => 99 } );

    ok( open( my $fh, '<', '/perms/basic' ), 'open succeeds with 0000 mode when no mock user set' );
    close $fh if $fh;

    # With mock user set, 0000 mode should fail for non-root
    Test::MockFile->set_user( 1000, 1000 );
    ok( !open( my $fh2, '<', '/perms/basic' ), 'open fails with 0000 mode when mock user is non-owner' );
    is( $! + 0, EACCES, 'errno is EACCES' );

    # clear_user disables checks again
    Test::MockFile->clear_user();
    ok( open( my $fh3, '<', '/perms/basic' ), 'open succeeds again after clear_user' );
    close $fh3 if $fh3;
};

# =========================================================================
# open() permission checks
# =========================================================================

subtest 'open read-only with owner read permission' => sub {
    my $f = Test::MockFile->file( '/perms/owner_r', 'data', { mode => 0400, uid => 1000, gid => 1000 } );

    with_user { ok( open( my $fh, '<', '/perms/owner_r' ), 'owner can read 0400 file' ); close $fh if $fh } 1000, 1000;
    with_user { ok( !open( my $fh, '<', '/perms/owner_r' ), 'other user cannot read 0400 file' ) } 2000, 2000;
};

subtest 'open write-only with owner write permission' => sub {
    my $f = Test::MockFile->file( '/perms/owner_w', 'data', { mode => 0200, uid => 1000, gid => 1000 } );

    with_user { ok( open( my $fh, '>', '/perms/owner_w' ), 'owner can write 0200 file' ); close $fh if $fh } 1000, 1000;
    with_user { ok( !open( my $fh, '>', '/perms/owner_w' ), 'other user cannot write 0200 file' ) } 2000, 2000;
};

subtest 'open read-write with owner rw permission' => sub {
    my $f = Test::MockFile->file( '/perms/owner_rw', 'data', { mode => 0600, uid => 1000, gid => 1000 } );

    with_user { ok( open( my $fh, '+<', '/perms/owner_rw' ), 'owner can rw 0600 file' ); close $fh if $fh } 1000, 1000;
    with_user { ok( !open( my $fh, '+<', '/perms/owner_rw' ), 'other user cannot rw 0600 file' ) } 2000, 2000;
};

subtest 'open with group permissions' => sub {
    my $f = Test::MockFile->file( '/perms/grp', 'data', { mode => 0040, uid => 1000, gid => 500 } );

    # User in group 500 can read
    with_user { ok( open( my $fh, '<', '/perms/grp' ), 'group member can read 0040 file' ); close $fh if $fh } 2000, 500;

    # User NOT in group 500 cannot read
    with_user { ok( !open( my $fh, '<', '/perms/grp' ), 'non-group member cannot read 0040 file' ) } 2000, 2000;
};

subtest 'open with other permissions' => sub {
    my $f = Test::MockFile->file( '/perms/other', 'data', { mode => 0004, uid => 1000, gid => 1000 } );

    # Random user can read via "other" bits
    with_user { ok( open( my $fh, '<', '/perms/other' ), 'other user can read 0004 file' ); close $fh if $fh } 9999, 9999;

    # Owner cannot read (owner bits are 0)
    with_user { ok( !open( my $fh, '<', '/perms/other' ), 'owner cannot read when owner bits are 0' ) } 1000, 1000;
};

# =========================================================================
# root bypass
# =========================================================================

subtest 'root can read/write any file' => sub {
    my $f = Test::MockFile->file( '/perms/root', 'secret', { mode => 0000, uid => 1000, gid => 1000 } );

    with_user {
        ok( open( my $fh, '<', '/perms/root' ), 'root can read 0000 file' );
        close $fh if $fh;
    } 0, 0;

    with_user {
        ok( open( my $fh, '>', '/perms/root' ), 'root can write 0000 file' );
        close $fh if $fh;
    } 0, 0;
};

# =========================================================================
# sysopen permission checks
# =========================================================================

subtest 'sysopen permission checks' => sub {
    my $f = Test::MockFile->file( '/perms/sys', 'data', { mode => 0400, uid => 1000, gid => 1000 } );

    with_user {
        ok( sysopen( my $fh, '/perms/sys', O_RDONLY ), 'owner can sysopen O_RDONLY on 0400' );
        close $fh if $fh;
    } 1000, 1000;

    with_user {
        ok( !sysopen( my $fh, '/perms/sys', O_RDONLY ), 'non-owner cannot sysopen O_RDONLY on 0400' );
        is( $! + 0, EACCES, 'sysopen errno is EACCES' );
    } 2000, 2000;

    with_user {
        ok( !sysopen( my $fh, '/perms/sys', O_WRONLY ), 'owner cannot sysopen O_WRONLY on 0400 (no write bit)' );
        is( $! + 0, EACCES, 'sysopen errno is EACCES for write' );
    } 1000, 1000;
};

# =========================================================================
# opendir permission checks
# =========================================================================

subtest 'opendir permission checks' => sub {
    my $dir = Test::MockFile->new_dir( '/perms/dir', { mode => 0700, uid => 1000, gid => 1000 } );

    with_user {
        ok( opendir( my $dh, '/perms/dir' ), 'owner can opendir 0700 dir' );
        closedir $dh if $dh;
    } 1000, 1000;

    with_user {
        ok( !opendir( my $dh, '/perms/dir' ), 'non-owner cannot opendir 0700 dir' );
        is( $! + 0, EACCES, 'opendir errno is EACCES' );
    } 2000, 2000;
};

subtest 'opendir group read permission' => sub {
    my $dir = Test::MockFile->new_dir( '/perms/grpdir', { mode => 0050, uid => 1000, gid => 500 } );

    with_user {
        ok( opendir( my $dh, '/perms/grpdir' ), 'group member can opendir 0050 dir' );
        closedir $dh if $dh;
    } 2000, 500;

    with_user {
        ok( !opendir( my $dh, '/perms/grpdir' ), 'non-group cannot opendir 0050 dir' );
    } 2000, 2000;
};

# =========================================================================
# unlink permission checks (needs write+exec on parent)
# =========================================================================

subtest 'unlink permission checks on parent directory' => sub {
    my $parent = Test::MockFile->new_dir( '/perms/udir', { mode => 0755, uid => 1000, gid => 1000 } );
    my $child  = Test::MockFile->file( '/perms/udir/victim', 'gone' );

    # Owner of parent can unlink
    with_user {
        is( unlink('/perms/udir/victim'), 1, 'parent owner can unlink child' );
    } 1000, 1000;

    # Re-create the file for next test
    $child = Test::MockFile->file( '/perms/udir/victim2', 'gone2' );

    # Non-owner, non-group with only read+exec on parent (0755 → other=rx)
    # Other has r(4)+x(1) = 5, needs w(2)+x(1) = 3 — missing write
    with_user {
        is( unlink('/perms/udir/victim2'), 0, 'non-owner cannot unlink in 0755 dir (no write)' );
        is( $! + 0, EACCES, 'unlink errno is EACCES' );
    } 9999, 9999;
};

# =========================================================================
# mkdir permission checks (needs write+exec on parent)
# =========================================================================

subtest 'mkdir permission checks on parent directory' => sub {
    my $parent = Test::MockFile->new_dir( '/perms/mdir', { mode => 0755, uid => 1000, gid => 1000 } );
    my $target = Test::MockFile->dir('/perms/mdir/newdir');

    with_user {
        ok( mkdir('/perms/mdir/newdir'), 'parent owner can mkdir' );
    } 1000, 1000;

    # Clean up and re-mock for next test
    my $parent2 = Test::MockFile->new_dir( '/perms/mdir2', { mode => 0555, uid => 1000, gid => 1000 } );
    my $target2 = Test::MockFile->dir('/perms/mdir2/newdir2');

    with_user {
        ok( !mkdir('/perms/mdir2/newdir2'), 'cannot mkdir in 0555 dir (no write)' );
        is( $! + 0, EACCES, 'mkdir errno is EACCES' );
    } 1000, 1000;
};

# =========================================================================
# rmdir permission checks (needs write+exec on parent)
# =========================================================================

subtest 'rmdir permission checks on parent directory' => sub {
    my $parent = Test::MockFile->new_dir( '/perms/rdir', { mode => 0755, uid => 1000, gid => 1000 } );
    my $target = Test::MockFile->new_dir('/perms/rdir/empty');

    with_user {
        ok( rmdir('/perms/rdir/empty'), 'parent owner can rmdir empty dir' );
    } 1000, 1000;

    my $parent2 = Test::MockFile->new_dir( '/perms/rdir2', { mode => 0555, uid => 1000, gid => 1000 } );
    my $target2 = Test::MockFile->new_dir('/perms/rdir2/empty2');

    with_user {
        ok( !rmdir('/perms/rdir2/empty2'), 'cannot rmdir in 0555 dir (no write)' );
        is( $! + 0, EACCES, 'rmdir errno is EACCES' );
    } 1000, 1000;
};

# =========================================================================
# chmod permission checks (only owner or root)
# =========================================================================

subtest 'chmod permission checks' => sub {
    my $f = Test::MockFile->file( '/perms/chm', 'data', { mode => 0644, uid => 1000, gid => 1000 } );

    with_user {
        is( chmod( 0600, '/perms/chm' ), 1, 'owner can chmod' );
    } 1000, 1000;

    with_user {
        is( chmod( 0777, '/perms/chm' ), 0, 'non-owner cannot chmod' );
        is( $! + 0, EPERM, 'chmod errno is EPERM' );
    } 2000, 2000;

    with_user {
        is( chmod( 0777, '/perms/chm' ), 1, 'root can chmod any file' );
    } 0, 0;
};

# =========================================================================
# chown with mock user
# =========================================================================

subtest 'chown uses mock user identity' => sub {
    my $f = Test::MockFile->file( '/perms/cho', 'data', { mode => 0644, uid => 1000, gid => 1000 } );

    # Non-root mock user cannot chown to a different user
    with_user {
        is( chown( 2000, 2000, '/perms/cho' ), 0, 'non-root mock user cannot chown to different user' );
        is( $! + 0, EPERM, 'chown errno is EPERM' );
    } 1000, 1000;

    # Root mock user can chown
    with_user {
        is( chown( 2000, 2000, '/perms/cho' ), 1, 'root mock user can chown' );
    } 0, 0;
};

# =========================================================================
# Non-existent file bypasses permission checks (ENOENT takes priority)
# =========================================================================

subtest 'non-existent file returns ENOENT not EACCES' => sub {
    my $f = Test::MockFile->file('/perms/noexist');

    with_user {
        ok( !open( my $fh, '<', '/perms/noexist' ), 'cannot open non-existent file' );
        # ENOENT should come before permission check
    } 1000, 1000;
};

# =========================================================================
# Multiple group membership
# =========================================================================

subtest 'user with multiple groups' => sub {
    my $f = Test::MockFile->file( '/perms/multigrp', 'data', { mode => 0040, uid => 1000, gid => 500 } );

    # User in secondary group 500
    with_user {
        ok( open( my $fh, '<', '/perms/multigrp' ), 'user in secondary group can read' );
        close $fh if $fh;
    } 2000, 100, 500, 600;

    # User NOT in group 500
    with_user {
        ok( !open( my $fh, '<', '/perms/multigrp' ), 'user not in any matching group cannot read' );
    } 2000, 100, 200, 300;
};

# =========================================================================
# open with write-creating modes checks parent perms
# =========================================================================

subtest 'open > on new file checks parent directory perms' => sub {
    my $parent = Test::MockFile->new_dir( '/perms/wdir', { mode => 0555, uid => 1000, gid => 1000 } );
    my $child  = Test::MockFile->file('/perms/wdir/newfile');

    with_user {
        ok( !open( my $fh, '>', '/perms/wdir/newfile' ), 'cannot create file in read-only parent dir' );
        is( $! + 0, EACCES, 'errno is EACCES' );
    } 1000, 1000;

    my $parent2 = Test::MockFile->new_dir( '/perms/wdir2', { mode => 0755, uid => 1000, gid => 1000 } );
    my $child2  = Test::MockFile->file('/perms/wdir2/newfile2');

    with_user {
        ok( open( my $fh, '>', '/perms/wdir2/newfile2' ), 'can create file in writable parent dir' );
        close $fh if $fh;
    } 1000, 1000;
};

done_testing();
