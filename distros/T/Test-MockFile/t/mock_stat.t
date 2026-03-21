#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;
use Overload::FileCheck qw/:check/;
use Errno qw/ELOOP ENOENT/;

use Cwd ();

# Assures testers don't mess up with our hard coded perms expectations.
umask 022;

note "_abs_path_to_file";
my $cwd = Cwd::getcwd();

is( Test::MockFile::_abs_path_to_file("0"), "$cwd/0", "no / prefix makes prepends path on it" );

is( Test::MockFile::_abs_path_to_file(), undef, "undef is undef" );

my @abs_path = (
    [ '/lib'                         => '/lib' ],
    [ '/lib/'                        => '/lib' ],
    [ '/abc/.'                       => '/abc' ],
    [ '/abc/./'                      => '/abc' ],
    [ '/abc/./././.'                 => '/abc' ],
    [ '/from/here/or-not/..'         => '/from/here' ],
    [ '/../../..'                    => '/' ],
    [ '/one/two/three/four/../../..' => '/one' ],
    [ '/a.b.c.d'                     => '/a.b.c.d' ],

    # Component-based resolution: /. in middle of path (GH #108)
    [ '/there/./xyz'                 => '/there/xyz' ],
    [ '/./foo'                       => '/foo' ],
    [ '/a/./b/./c'                   => '/a/b/c' ],

    # Component-based resolution: /.. at various positions
    [ '/there/..'                    => '/' ],
    [ '/..'                          => '/' ],
    [ '/../foo'                      => '/foo' ],
    [ '/there/sub/../file'           => '/there/file' ],
    [ '/a/b/c/../../d'              => '/a/d' ],

    # Root path preservation
    [ '/'                            => '/' ],

    # Multiple slashes
    [ '/foo//bar'                    => '/foo/bar' ],
    [ '///foo///bar///'              => '/foo/bar' ],
);
foreach my $t (@abs_path) {
    my ( $path, $normalized_path ) = @$t;
    is( Test::MockFile::_abs_path_to_file($path), $normalized_path, "_abs_path_to_file( '$path' ) = '$normalized_path'" );
}

note "_fh_to_file";
my @mocked_files;

push @mocked_files, Test::MockFile->file( '/foo/bar', "" );
push @mocked_files, Test::MockFile->file( '/bar/foo', "" );
open( my $fh,  "<", "/foo/bar" ) or die;
open( my $fh2, "<", "/bar/foo" ) or die;

is( Test::MockFile::_fh_to_file(),              undef, "_fh_to_file()" );
is( Test::MockFile::_fh_to_file(0),             undef, "_fh_to_file(0)" );
is( Test::MockFile::_fh_to_file(''),            undef, "_fh_to_file('')" );
is( Test::MockFile::_fh_to_file(' '),           undef, "_fh_to_file(' ')" );
is( Test::MockFile::_fh_to_file('/etc/passwd'), undef, "_fh_to_file('/etc/passwd')" );

is( Test::MockFile::_fh_to_file($fh),  '/foo/bar', "_fh_to_file(\$fh)" );
is( Test::MockFile::_fh_to_file($fh2), '/bar/foo', "_fh_to_file(\$fh2)" );
close $fh;
close $fh2;
is( Test::MockFile::_fh_to_file($fh), undef, "_fh_to_file(\$fh) when closed." );

note "_find_file_or_fh";
push @mocked_files, Test::MockFile->symlink( '/foo/bar', '/abc' );
is( Test::MockFile::_find_file_or_fh('/abc'),      '/abc',     "_find_file_or_fh('/abc')" );
is( Test::MockFile::_find_file_or_fh( '/abc', 1 ), '/foo/bar', "_find_file_or_fh('/abc', 1) - follow" );

push @mocked_files, Test::MockFile->symlink( '/not/a/file', '/broken_link' );
is( Test::MockFile::_find_file_or_fh( '/broken_link', 1 ), Test::MockFile::BROKEN_SYMLINK(), "_find_file_or_fh('/broken_link', 1) is undef when /broken_link is mocked." );

push @mocked_files, Test::MockFile->symlink( '/aaa', '/bbb' );
push @mocked_files, Test::MockFile->symlink( '/bbb', '/aaa' );
is( Test::MockFile::_find_file_or_fh( '/aaa', 1 ), Test::MockFile::CIRCULAR_SYMLINK(), "_find_file_or_fh('/aaaa', 1) - with circular links" );
is( $! + 0,                                        ELOOP,                              '$! is ELOOP' );

note "_mock_stat";

is( Test::MockFile::_mock_stat( 'lstat', "/lib" ), FALLBACK_TO_REAL_OP(), "An unmocked file will return FALLBACK_TO_REAL_OP() to tell XS to handle it" );
like( dies { Test::MockFile::_mock_stat() },                 qr/^_mock_stat called without a stat type at /, "no args fails cause we should have gotten a stat type." );
like( dies { Test::MockFile::_mock_stat( 'notastat', '' ) }, qr/^Unexpected stat type 'notastat' at /,       "An unknown stat type fails cause this should never happen." );
is( Test::MockFile::_mock_stat( 'lstat', "" ),  FALLBACK_TO_REAL_OP(), "empty string passes to XS" );
is( Test::MockFile::_mock_stat( 'stat',  ' ' ), FALLBACK_TO_REAL_OP(), "A space string passes to XS" );

my $basic_stat_return = array {
    item 0;
    item match qr/^[1-9][0-9]*$/;    # inode: unique positive integer
    item 0100644;
    item 1;                           # nlink: 1 for regular files
    item match qr/^[0-9]+$/;
    item match qr/^[0-9\s]+$/;
    item 0;
    item 0;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item 4096;
    item 0;
};

is( Test::MockFile::_mock_stat( 'lstat', '/foo/bar' ), $basic_stat_return, "/foo/bar mock stat" );
is( Test::MockFile::_mock_stat( 'stat',  '/aaa' ),     0,                  "/aaa mock stat when looped." );
is( $! + 0, ELOOP, "Throws an ELOOP error" );

push @mocked_files, Test::MockFile->file('/foo/baz');    # Missing file but mocked.
is( Test::MockFile::_mock_stat( 'lstat', '/foo/baz' ), 0, "/foo/baz mock stat when missing." );
is( $! + 0, ENOENT, "Throws an ENOENT error for missing file" );

my $symlink_lstat_return = array {
    item 0;
    item match qr/^[1-9][0-9]*$/;    # inode: unique positive integer
    item 0127777;
    item 1;                           # nlink: 1 for symlinks
    item match qr/^[0-9]+$/;
    item match qr/^[0-9\s]+$/;
    item 0;
    item 11;    # length('/not/a/file') - symlink size = length of target path
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item 4096;
    item 1;
};

is( Test::MockFile::_mock_stat( 'lstat', '/broken_link' ), $symlink_lstat_return, "lstat on /broken_link returns the stat on the symlink itself." );
is( Test::MockFile::_mock_stat( 'stat',  '/broken_link' ), 0,                     "stat on /broken_link returns 0 since what it points to doesn't exist." );

{
    my $exe = q[/tmp/custom.exe];
    my $tmp = Test::MockFile->file( $exe, " ", { mode => 0700 } );
    ok -x $exe, "mocked file is executable";

    my (
        $dev,   $ino,   $mode,  $nlink,   $uid, $gid, $rdev, $size,
        $atime, $mtime, $ctime, $blksize, $blocks
    ) = stat($exe);

    is $uid, $>, 'default uid is current UID';
    note "GID $gid";
    is $gid, int $), 'default fid is current GID';
}

{
    # make sure directories with trailing slash are not ignored by stat by accident
    my $dir = Test::MockFile->dir('/quux');
    mkdir $dir->path();
    ok( -d ( $dir->path() ),       'Directory /quux exists' );
    ok( -d ( $dir->path() . '/' ), 'Directory /quux/ also exists' );
}

note "path canonicalization — stat resolves . and .. components (GH #108)";
{
    my $dir  = Test::MockFile->dir('/there');
    my $file = Test::MockFile->file( '/there/xyz', "content" );
    mkdir '/there';

    # /there/. should resolve to /there
    ok( -d '/there/.',     '-d "/there/." resolves to mocked /there' );

    # /there/./xyz should resolve to /there/xyz
    ok( -e '/there/./xyz', '-e "/there/./xyz" resolves to mocked /there/xyz' );
    ok( -f '/there/./xyz', '-f "/there/./xyz" resolves to mocked /there/xyz' );

    # stat on paths with . component
    my @st = stat('/there/./xyz');
    ok( scalar @st, 'stat("/there/./xyz") returns stat data' );
}

{
    my $parent = Test::MockFile->dir('/up');
    my $child  = Test::MockFile->dir('/up/down');
    mkdir '/up';
    mkdir '/up/down';

    # /up/down/.. should resolve to /up
    ok( -d '/up/down/..',  '-d "/up/down/.." resolves to mocked /up' );
}

note "directory stat size returns blksize, not stringified arrayref length";
{
    my $dir = Test::MockFile->new_dir('/stat_dir_size');
    my $child = Test::MockFile->file( '/stat_dir_size/a', 'data' );

    my @st = stat('/stat_dir_size');
    is( $st[7], 4096, 'directory stat size is blksize (4096), not stringified ref length' );

    my $s = -s '/stat_dir_size';
    is( $s, 4096, '-s on directory returns blksize' );
}

done_testing();
exit;
