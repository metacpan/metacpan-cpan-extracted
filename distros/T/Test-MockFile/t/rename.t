#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EISDIR ENOTDIR ENOTEMPTY/;

use Test::MockFile qw< nostrict >;

note "-------------- rename: basic file rename --------------";
{
    my $old = Test::MockFile->file( '/mock/old', 'content' );
    my $new = Test::MockFile->file('/mock/new');

    ok( rename( '/mock/old', '/mock/new' ), 'rename returns true' );
    is( $old->contents, undef,     'old file contents cleared' );
    is( $new->contents, 'content', 'new file has old contents' );
}

note "-------------- rename: non-existent source --------------";
{
    my $old = Test::MockFile->file('/mock/noexist');
    my $new = Test::MockFile->file('/mock/dest');

    ok( !rename( '/mock/noexist', '/mock/dest' ), 'rename fails for non-existent source' );
    is( $! + 0, ENOENT, 'errno is ENOENT' );
}

note "-------------- rename: overwrite existing file --------------";
{
    my $old = Test::MockFile->file( '/mock/src', 'new content' );
    my $new = Test::MockFile->file( '/mock/dst', 'old content' );

    ok( rename( '/mock/src', '/mock/dst' ), 'rename overwrites existing file' );
    is( $new->contents, 'new content', 'destination has new contents' );
    is( $old->contents, undef,         'source is gone' );
}

note "-------------- rename: file to existing directory fails --------------";
{
    my $old = Test::MockFile->file( '/mock/file', 'data' );
    my $dir = Test::MockFile->new_dir('/mock/dir');

    ok( !rename( '/mock/file', '/mock/dir' ), 'cannot rename file over directory' );
    is( $! + 0, EISDIR, 'errno is EISDIR' );
}

note "-------------- rename: preserves file mode --------------";
{
    my $old = Test::MockFile->file( '/mock/moded', 'data', { mode => 0755 } );
    my $new = Test::MockFile->file('/mock/modedest');

    my $old_mode = $old->{'mode'};
    ok( rename( '/mock/moded', '/mock/modedest' ), 'rename preserves mode' );
    is( $new->{'mode'}, $old_mode, 'destination has source mode' );
}

note "-------------- rename: empty directory rename --------------";
{
    my $old = Test::MockFile->new_dir('/mock/olddir');
    my $new = Test::MockFile->dir('/mock/newdir');

    ok( rename( '/mock/olddir', '/mock/newdir' ), 'rename empty directory works' );
    ok( !$old->exists,                            'old dir no longer exists' );
    ok( $new->exists,                             'new dir exists' );
}

note "-------------- rename: symlink rename --------------";
{
    my $target = Test::MockFile->file( '/mock/target', 'data' );
    my $link   = Test::MockFile->symlink( '/mock/target', '/mock/link' );
    my $dest   = Test::MockFile->file('/mock/linkdest');

    ok( rename( '/mock/link', '/mock/linkdest' ), 'rename symlink works' );
    ok( !$link->is_link || !defined $link->readlink, 'old symlink is gone' );
}

note "-------------- rename: dir over existing file fails --------------";
{
    my $dir  = Test::MockFile->new_dir('/mock/adir');
    my $file = Test::MockFile->file( '/mock/afile', 'data' );

    ok( !rename( '/mock/adir', '/mock/afile' ), 'cannot rename dir over file' );
    is( $! + 0, ENOTDIR, 'errno is ENOTDIR' );
}

note "-------------- rename: file to self is no-op (POSIX) --------------";
{
    my $file = Test::MockFile->file( '/mock/self', 'precious data' );

    ok( rename( '/mock/self', '/mock/self' ), 'rename to self returns true' );
    is( $file->contents, 'precious data', 'file contents preserved after rename to self' );
    ok( $file->exists, 'file still exists after rename to self' );
}

note "-------------- rename: directory to self is no-op (POSIX) --------------";
{
    my $dir = Test::MockFile->new_dir('/mock/selfdir');

    ok( rename( '/mock/selfdir', '/mock/selfdir' ), 'rename dir to self returns true' );
    ok( $dir->exists, 'directory still exists after rename to self' );
}

note "-------------- rename: symlink to self is no-op (POSIX) --------------";
{
    my $target = Test::MockFile->file( '/mock/selflink_target', 'data' );
    my $link   = Test::MockFile->symlink( '/mock/selflink_target', '/mock/selflink' );

    ok( rename( '/mock/selflink', '/mock/selflink' ), 'rename symlink to self returns true' );
    ok( $link->is_link, 'symlink still a link after rename to self' );
    is( readlink('/mock/selflink'), '/mock/selflink_target', 'symlink target preserved after rename to self' );
}

note "-------------- rename: dir over non-empty dir fails (ENOTEMPTY) --------------";
{
    my $src   = Test::MockFile->new_dir('/mock/srcdir');
    my $dst   = Test::MockFile->new_dir('/mock/fulldir');
    my $child = Test::MockFile->file( '/mock/fulldir/child', 'data' );

    ok( !rename( '/mock/srcdir', '/mock/fulldir' ), 'cannot rename dir over non-empty dir' );
    is( $! + 0, ENOTEMPTY, 'errno is ENOTEMPTY' );
    ok( $src->exists,   'source dir still exists after failed rename' );
    ok( $dst->exists,   'dest dir still exists after failed rename' );
    ok( $child->exists, 'child file still exists after failed rename' );
}

note "-------------- rename: dir over empty dir succeeds (POSIX) --------------";
{
    my $src = Test::MockFile->new_dir('/mock/srcdir2');
    my $dst = Test::MockFile->new_dir('/mock/emptydir');

    ok( rename( '/mock/srcdir2', '/mock/emptydir' ), 'rename dir over empty dir succeeds' );
    ok( !$src->exists, 'source dir no longer exists' );
    ok( $dst->exists,  'dest dir exists after rename' );
}

note "-------------- rename: directory with child file re-keys children --------------";
{
    my $dir   = Test::MockFile->new_dir('/mock/parent');
    my $child = Test::MockFile->file( '/mock/parent/child.txt', 'hello world' );
    my $dest  = Test::MockFile->dir('/mock/renamed');

    ok( rename( '/mock/parent', '/mock/renamed' ), 'rename directory with child succeeds' );
    ok( !$dir->exists,  'old directory no longer exists' );
    ok( $dest->exists,  'new directory exists' );

    # Child should be accessible under new path
    my $child_exists = -e '/mock/renamed/child.txt';
    ok( $child_exists, 'child file exists under new directory path' );

    # Child contents should be preserved
    open( my $fh, '<', '/mock/renamed/child.txt' ) or die "open failed: $!";
    my $got = do { local $/; <$fh> };
    close $fh;
    is( $got, 'hello world', 'child file contents preserved after directory rename' );

    # Child should NOT be accessible under old path
    ok( !-e '/mock/parent/child.txt', 'child file not accessible under old path' );
}

note "-------------- rename: directory with nested subdirectory --------------";
{
    my $dir    = Test::MockFile->new_dir('/mock/top');
    my $subdir = Test::MockFile->new_dir('/mock/top/sub');
    my $file   = Test::MockFile->file( '/mock/top/sub/deep.txt', 'nested' );
    my $dest   = Test::MockFile->dir('/mock/newtop');

    ok( rename( '/mock/top', '/mock/newtop' ), 'rename directory with nested subdirectory succeeds' );

    # Nested subdirectory accessible under new path
    ok( -d '/mock/newtop/sub', 'nested subdirectory exists under new path' );

    # Deep file accessible under new path
    my $deep_exists = -e '/mock/newtop/sub/deep.txt';
    ok( $deep_exists, 'deeply nested file exists under new path' );

    open( my $fh, '<', '/mock/newtop/sub/deep.txt' ) or die "open failed: $!";
    my $got = do { local $/; <$fh> };
    close $fh;
    is( $got, 'nested', 'deeply nested file contents preserved' );

    # Old paths should not exist
    ok( !-e '/mock/top/sub/deep.txt', 'deep file not accessible under old path' );
    ok( !-d '/mock/top/sub',          'nested subdir not accessible under old path' );
}

note "-------------- rename: directory readdir shows re-keyed children --------------";
{
    my $dir  = Test::MockFile->new_dir('/mock/rd_old');
    my $f1   = Test::MockFile->file( '/mock/rd_old/a.txt', 'aaa' );
    my $f2   = Test::MockFile->file( '/mock/rd_old/b.txt', 'bbb' );
    my $dest = Test::MockFile->dir('/mock/rd_new');

    ok( rename( '/mock/rd_old', '/mock/rd_new' ), 'rename directory for readdir test' );

    opendir( my $dh, '/mock/rd_new' ) or die "opendir failed: $!";
    my @entries = sort readdir($dh);
    closedir($dh);

    is( \@entries, [ '.', '..', 'a.txt', 'b.txt' ], 'readdir on renamed directory shows re-keyed children' );
}

note "-------------- rename: child mock object path updated after rename --------------";
{
    my $dir   = Test::MockFile->new_dir('/mock/pathtest');
    my $child = Test::MockFile->file( '/mock/pathtest/item.dat', 'data' );
    my $dest  = Test::MockFile->dir('/mock/pathtest2');

    ok( rename( '/mock/pathtest', '/mock/pathtest2' ), 'rename for path update test' );

    is( $child->path, '/mock/pathtest2/item.dat', 'child mock object path updated to new prefix' );
}

note "-------------- rename: directory DESTROY cleanup works after rename --------------";
{
    my $dir  = Test::MockFile->new_dir('/mock/dtor');
    my $file = Test::MockFile->file( '/mock/dtor/f.txt', 'content' );
    my $dest = Test::MockFile->dir('/mock/dtor2');

    ok( rename( '/mock/dtor', '/mock/dtor2' ), 'rename for DESTROY test' );

    # Verify child still exists under new path before cleanup
    ok( -e '/mock/dtor2/f.txt', 'child accessible before DESTROY' );
}

note "-------------- rename: preserves inode and nlink --------------";
{
    my $old = Test::MockFile->file( '/mock/ino_old', 'data', { inode => 42, nlink => 3 } );
    my $new = Test::MockFile->file('/mock/ino_new');

    ok( rename( '/mock/ino_old', '/mock/ino_new' ), 'rename preserves inode metadata' );

    my @st = stat('/mock/ino_new');
    is( $st[1], 42, 'inode preserved after rename' );
    is( $st[3], 3,  'nlink preserved after rename' );
}

done_testing();
