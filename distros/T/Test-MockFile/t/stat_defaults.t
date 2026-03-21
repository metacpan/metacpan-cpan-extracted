#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

# Ensure consistent umask for permission tests
umask 022;

note "--- nlink defaults ---";

subtest 'regular file has nlink=1' => sub {
    my $f = Test::MockFile->file( '/mock/nlink_file', 'data' );

    my $nlink = ( stat('/mock/nlink_file') )[3];
    is( $nlink, 1, 'nlink is 1 for regular file' );
};

subtest 'directory has nlink=2' => sub {
    my $d = Test::MockFile->new_dir('/mock/nlink_dir');

    my $nlink = ( stat('/mock/nlink_dir') )[3];
    is( $nlink, 2, 'nlink is 2 for directory' );
};

subtest 'symlink has nlink=1' => sub {
    my $target = Test::MockFile->file( '/mock/nlink_target', 'data' );
    my $link   = Test::MockFile->symlink( '/mock/nlink_target', '/mock/nlink_sym' );

    my $nlink = ( lstat('/mock/nlink_sym') )[3];
    is( $nlink, 1, 'nlink is 1 for symlink' );
};

subtest 'mkdir sets nlink=2' => sub {
    my $d = Test::MockFile->dir('/mock/nlink_mkdir');
    mkdir '/mock/nlink_mkdir';

    my $nlink = ( stat('/mock/nlink_mkdir') )[3];
    is( $nlink, 2, 'nlink is 2 after mkdir' );
};

subtest 'link increments nlink correctly from 1' => sub {
    my $src  = Test::MockFile->file( '/mock/link_src', 'content' );
    my $dest = Test::MockFile->file('/mock/link_dest');

    my $before = ( stat('/mock/link_src') )[3];
    is( $before, 1, 'nlink starts at 1 before linking' );

    link( '/mock/link_src', '/mock/link_dest' );

    my $src_nlink  = ( stat('/mock/link_src') )[3];
    my $dest_nlink = ( stat('/mock/link_dest') )[3];

    is( $src_nlink,  2, 'source nlink is 2 after link' );
    is( $dest_nlink, 2, 'destination nlink is 2 after link' );
};

subtest 'user-specified nlink overrides default' => sub {
    my $f = Test::MockFile->file( '/mock/nlink_custom', 'data', { nlink => 5 } );

    my $nlink = ( stat('/mock/nlink_custom') )[3];
    is( $nlink, 5, 'user-specified nlink=5 is preserved' );
};

note "--- inode defaults ---";

subtest 'each mock gets a unique inode' => sub {
    my $f1 = Test::MockFile->file( '/mock/ino_a', 'aaa' );
    my $f2 = Test::MockFile->file( '/mock/ino_b', 'bbb' );
    my $f3 = Test::MockFile->file( '/mock/ino_c', 'ccc' );

    my $ino1 = ( stat('/mock/ino_a') )[1];
    my $ino2 = ( stat('/mock/ino_b') )[1];
    my $ino3 = ( stat('/mock/ino_c') )[1];

    ok( $ino1 > 0, 'inode is non-zero' );
    ok( $ino2 > 0, 'inode is non-zero' );
    ok( $ino3 > 0, 'inode is non-zero' );

    isnt( $ino1, $ino2, 'file A and B have different inodes' );
    isnt( $ino2, $ino3, 'file B and C have different inodes' );
    isnt( $ino1, $ino3, 'file A and C have different inodes' );
};

subtest 'directory gets a unique inode' => sub {
    my $f = Test::MockFile->file( '/mock/ino_file', 'data' );
    my $d = Test::MockFile->new_dir('/mock/ino_dir');

    my $f_ino = ( stat('/mock/ino_file') )[1];
    my $d_ino = ( stat('/mock/ino_dir') )[1];

    ok( $d_ino > 0, 'directory inode is non-zero' );
    isnt( $f_ino, $d_ino, 'file and directory have different inodes' );
};

subtest 'symlink gets a unique inode' => sub {
    my $target = Test::MockFile->file( '/mock/ino_sym_tgt', 'data' );
    my $link   = Test::MockFile->symlink( '/mock/ino_sym_tgt', '/mock/ino_sym_lnk' );

    my $t_ino = ( stat('/mock/ino_sym_tgt') )[1];
    my $l_ino = ( lstat('/mock/ino_sym_lnk') )[1];

    ok( $l_ino > 0, 'symlink inode is non-zero' );
    isnt( $t_ino, $l_ino, 'symlink and target have different inodes' );
};

subtest 'hard links share the same inode' => sub {
    my $src  = Test::MockFile->file( '/mock/ino_hard_src', 'data' );
    my $dest = Test::MockFile->file('/mock/ino_hard_dest');

    link( '/mock/ino_hard_src', '/mock/ino_hard_dest' );

    my $src_ino  = ( stat('/mock/ino_hard_src') )[1];
    my $dest_ino = ( stat('/mock/ino_hard_dest') )[1];

    is( $dest_ino, $src_ino, 'hard link has same inode as source' );
};

subtest 'user-specified inode overrides default' => sub {
    my $f = Test::MockFile->file( '/mock/ino_custom', 'data', { inode => 42 } );

    my $ino = ( stat('/mock/ino_custom') )[1];
    is( $ino, 42, 'user-specified inode=42 is preserved' );
};

done_testing();
