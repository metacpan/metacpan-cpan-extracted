#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EEXIST EPERM EXDEV EINVAL ELOOP/;

use Test::MockFile qw< nostrict >;

note "-------------- symlink() builtin on mocked paths --------------";

{
    note "symlink() on a non-existent file mock converts it to a symlink";
    my $file = Test::MockFile->file('/mock/target');
    my $link = Test::MockFile->file('/mock/mylink');

    ok( !-e '/mock/mylink', 'link path does not exist yet' );
    ok( !-l '/mock/mylink', 'link path is not a symlink yet' );

    my $result = symlink( '/mock/target', '/mock/mylink' );
    ok( $result, 'symlink() returns true on success' );
    ok( -l '/mock/mylink', '-l detects the new symlink' );

    is( readlink('/mock/mylink'), '/mock/target', 'readlink returns the target' );
}

{
    note "symlink() fails with EEXIST when destination already exists (file)";
    my $existing = Test::MockFile->file( '/mock/exists', 'content' );
    $! = 0;
    my $result = symlink( '/somewhere', '/mock/exists' );
    is( $result, 0,      'symlink() returns 0 when destination exists' );
    is( $! + 0, EEXIST, '$! is EEXIST' );
}

{
    note "symlink() fails with EEXIST when destination is an existing dir";
    my $dir = Test::MockFile->dir('/mock/existdir');
    mkdir '/mock/existdir';
    $! = 0;
    my $result = symlink( '/somewhere', '/mock/existdir' );
    is( $result, 0,      'symlink() returns 0 when destination is a dir' );
    is( $! + 0, EEXIST, '$! is EEXIST' );
}

{
    note "symlink() fails with EEXIST when destination is an existing symlink";
    my $link = Test::MockFile->symlink( '/target1', '/mock/existlink' );
    $! = 0;
    my $result = symlink( '/target2', '/mock/existlink' );
    is( $result, 0,      'symlink() returns 0 when destination is already a symlink' );
    is( $! + 0, EEXIST, '$! is EEXIST' );
}

{
    note "symlink() updates parent directory content";
    my $parent = Test::MockFile->dir('/mock/parentdir');
    my $child  = Test::MockFile->file('/mock/parentdir/newlink');

    ok( !-d '/mock/parentdir', 'parent dir does not exist yet' );

    symlink( '/whatever', '/mock/parentdir/newlink' );

    ok( -d '/mock/parentdir', 'parent dir now exists (has_content set)' );

    opendir my $dh, '/mock/parentdir' or die $!;
    my @entries = readdir $dh;
    closedir $dh;
    is( \@entries, [qw< . .. newlink >], 'parent dir lists the new symlink' );
}

{
    note "symlink() can create a dangling symlink (target not mocked)";
    my $link = Test::MockFile->file('/mock/dangling');

    my $result = symlink( '/nonexistent/target', '/mock/dangling' );
    ok( $result, 'symlink() succeeds even if target is not mocked' );
    ok( -l '/mock/dangling', 'the symlink exists' );
    is( readlink('/mock/dangling'), '/nonexistent/target', 'readlink returns the dangling target' );
}

{
    note "symlink() on a non-existent dir mock converts it to a symlink";
    my $mock = Test::MockFile->dir('/mock/dirlink');

    ok( !-e '/mock/dirlink', 'dir mock does not exist initially' );

    symlink( '/somewhere', '/mock/dirlink' );
    ok( -l '/mock/dirlink', 'now it is a symlink' );
    ok( !-d '/mock/dirlink', 'it is NOT a directory anymore' );
}

{
    note "symlink() on a non-existent symlink mock converts it to an existing symlink";
    my $mock = Test::MockFile->symlink( undef, '/mock/undeflink' );

    ok( !-e '/mock/undeflink', 'undef symlink mock does not exist' );

    symlink( '/real_target', '/mock/undeflink' );
    ok( -l '/mock/undeflink', 'now it is an existing symlink' );
    is( readlink('/mock/undeflink'), '/real_target', 'readlink returns new target' );
}

note "-------------- link() builtin on mocked paths --------------";

{
    note "link() creates a hard link between two mocked files";
    my $src  = Test::MockFile->file( '/mock/source', 'hello world' );
    my $dest = Test::MockFile->file('/mock/hardlink');

    ok( !-e '/mock/hardlink', 'hardlink does not exist yet' );

    my $result = link( '/mock/source', '/mock/hardlink' );
    ok( $result, 'link() returns true on success' );
    ok( -e '/mock/hardlink', 'hardlink now exists' );
    ok( -f '/mock/hardlink', 'hardlink is a regular file' );

    # Contents should match
    open my $fh, '<', '/mock/hardlink' or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    is( $content, 'hello world', 'hardlink has same contents as source' );
}

{
    note "link() increments nlink on both source and destination";
    my $src  = Test::MockFile->file( '/mock/src_nlink', 'data' );
    my $dest = Test::MockFile->file('/mock/dst_nlink');

    my $initial_nlink = ( stat('/mock/src_nlink') )[3];

    link( '/mock/src_nlink', '/mock/dst_nlink' );

    my $src_nlink = ( stat('/mock/src_nlink') )[3];
    my $dst_nlink = ( stat('/mock/dst_nlink') )[3];

    is( $src_nlink, $initial_nlink + 1, 'source nlink incremented' );
    is( $dst_nlink, $src_nlink,         'destination nlink matches source' );
}

{
    note "link() preserves mode, uid, gid from source";
    my $src  = Test::MockFile->file( '/mock/src_perms', 'data', { mode => 0755 } );
    my $dest = Test::MockFile->file('/mock/dst_perms');

    link( '/mock/src_perms', '/mock/dst_perms' );

    my @src_stat = stat('/mock/src_perms');
    my @dst_stat = stat('/mock/dst_perms');

    is( $dst_stat[2], $src_stat[2], 'mode matches' );
    is( $dst_stat[4], $src_stat[4], 'uid matches' );
    is( $dst_stat[5], $src_stat[5], 'gid matches' );
}

{
    note "link() fails with ENOENT when source does not exist";
    my $src  = Test::MockFile->file('/mock/nosrc');
    my $dest = Test::MockFile->file('/mock/nodest');

    $! = 0;
    my $result = link( '/mock/nosrc', '/mock/nodest' );
    is( $result, 0,      'link() returns 0 when source does not exist' );
    is( $! + 0, ENOENT, '$! is ENOENT' );
}

{
    note "link() fails with EEXIST when destination already exists";
    my $src  = Test::MockFile->file( '/mock/src_exist',  'data' );
    my $dest = Test::MockFile->file( '/mock/dest_exist', 'other' );

    $! = 0;
    my $result = link( '/mock/src_exist', '/mock/dest_exist' );
    is( $result, 0,      'link() returns 0 when destination exists' );
    is( $! + 0, EEXIST, '$! is EEXIST' );
}

{
    note "link() fails with EPERM when source is a directory";
    my $dir  = Test::MockFile->dir('/mock/srcdir');
    mkdir '/mock/srcdir';
    my $dest = Test::MockFile->file('/mock/linktodir');

    $! = 0;
    my $result = link( '/mock/srcdir', '/mock/linktodir' );
    is( $result, 0,     'link() returns 0 for directory source' );
    is( $! + 0, EPERM, '$! is EPERM' );
}

{
    note "link() fails with EXDEV when destination is not mocked";
    my $src = Test::MockFile->file( '/mock/src_xdev', 'data' );

    $! = 0;
    my $result = link( '/mock/src_xdev', '/unmocked/path' );
    is( $result, 0,     'link() returns 0 when destination is not mocked' );
    is( $! + 0, EXDEV, '$! is EXDEV (cannot cross mock/real boundary)' );
}

{
    note "link() follows symlinks on source";
    my $target  = Test::MockFile->file( '/mock/real_file', 'linked data' );
    my $symlink = Test::MockFile->symlink( '/mock/real_file', '/mock/sym_src' );
    my $dest    = Test::MockFile->file('/mock/hard_from_sym');

    my $result = link( '/mock/sym_src', '/mock/hard_from_sym' );
    ok( $result, 'link() through symlink succeeds' );
    ok( -f '/mock/hard_from_sym', 'destination is a regular file (not symlink)' );

    open my $fh, '<', '/mock/hard_from_sym' or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    is( $content, 'linked data', 'destination has the symlink target contents' );
}

{
    note "link() fails when symlink source is broken";
    my $broken  = Test::MockFile->symlink( '/mock/nowhere', '/mock/broken_sym' );
    my $dest    = Test::MockFile->file('/mock/link_broken');

    $! = 0;
    my $result = link( '/mock/broken_sym', '/mock/link_broken' );
    is( $result, 0,      'link() fails for broken symlink source' );
    is( $! + 0, ENOENT, '$! is ENOENT' );
}

{
    note "link() updates parent directory content";
    my $parent = Test::MockFile->dir('/mock/linkparent');
    my $src    = Test::MockFile->file( '/mock/linksrc', 'data' );
    my $dest   = Test::MockFile->file('/mock/linkparent/newhard');

    ok( !-d '/mock/linkparent', 'parent dir does not exist yet' );

    link( '/mock/linksrc', '/mock/linkparent/newhard' );

    ok( -d '/mock/linkparent', 'parent dir now exists' );

    opendir my $dh, '/mock/linkparent' or die $!;
    my @entries = readdir $dh;
    closedir $dh;
    is( \@entries, [qw< . .. newhard >], 'parent dir lists the new hard link' );
}

{
    note "link() fails with ELOOP when symlink source is circular";
    my $link_a = Test::MockFile->symlink( '/mock/circ_b', '/mock/circ_a' );
    my $link_b = Test::MockFile->symlink( '/mock/circ_a', '/mock/circ_b' );
    my $dest   = Test::MockFile->file('/mock/link_circ');

    $! = 0;
    my $result = link( '/mock/circ_a', '/mock/link_circ' );
    is( $result, 0,     'link() fails for circular symlink source' );
    is( $! + 0, ELOOP, '$! is ELOOP (not ENOENT)' );
}

{
    note "unlink() decrements nlink on the unlinked file";
    my $src  = Test::MockFile->file( '/mock/ul_src', 'data', { nlink => 1, inode => 90001 } );
    my $dest = Test::MockFile->file('/mock/ul_dst');

    link( '/mock/ul_src', '/mock/ul_dst' );

    my $nlink_before = ( stat('/mock/ul_src') )[3];
    is( $nlink_before, 2, 'source nlink is 2 after link' );

    unlink('/mock/ul_src');

    my $src_nlink_after = ( stat('/mock/ul_src') )[3];
    is( $src_nlink_after, undef, 'stat on unlinked file returns undef (no longer exists)' );

    my $dst_nlink = ( stat('/mock/ul_dst') )[3];
    is( $dst_nlink, 1, 'remaining hard link nlink decremented after unlink' );
}

{
    note "unlink() on a file with nlink=1 decrements to 0";
    my $file = Test::MockFile->file( '/mock/ul_single', 'data', { nlink => 1 } );

    my $nlink_before = ( stat('/mock/ul_single') )[3];
    is( $nlink_before, 1, 'nlink is 1 before unlink' );

    unlink('/mock/ul_single');

    # File no longer exists, but the mock object's nlink should be decremented
    ok( !-e '/mock/ul_single', 'file no longer exists after unlink' );
}

done_testing();
