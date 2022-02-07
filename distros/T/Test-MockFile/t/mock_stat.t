#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile ();
use Overload::FileCheck qw/:check/;
use Errno qw/ELOOP/;

use Cwd ();

# Assures testers don't mess up with our hard coded perms expectations.
umask 022;

note "_abs_path_to_file";
my $cwd = Cwd::getcwd();
is( Test::MockFile::_abs_path_to_file("0"),    "$cwd/0", "no / prefix makes prepends path on it." );
is( Test::MockFile::_abs_path_to_file("/lib"), "/lib",   "/lib is /lib" );
is( Test::MockFile::_abs_path_to_file(),       undef,    "undef is undef" );

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
    item 0;
    item 0100644;
    item 0;
    item match qr/^[0-9]+$/;
    item match qr/^[0-9\s]+$/;
    item 0;
    item 0;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item 4096;
    item 1;
};

is( Test::MockFile::_mock_stat( 'lstat', '/foo/bar' ), $basic_stat_return, "/foo/bar mock stat" );
is( Test::MockFile::_mock_stat( 'stat',  '/aaa' ),     [],                 "/aaa mock stat when looped." );
is( $! + 0, ELOOP, "Throws an ELOOP error" );

push @mocked_files, Test::MockFile->file('/foo/baz');    # Missing file but mocked.
is( Test::MockFile::_mock_stat( 'lstat', '/foo/baz' ), [], "/foo/baz mock stat when missing." );

my $symlink_lstat_return = array {
    item 0;
    item 0;
    item 0127777;
    item 0;
    item match qr/^[0-9]+$/;
    item match qr/^[0-9\s]+$/;
    item 0;
    item 1;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item match qr/^[0-9]{3,}$/;
    item 4096;
    item 1;
};

is( Test::MockFile::_mock_stat( 'lstat', '/broken_link' ), $symlink_lstat_return, "lstat on /broken_link returns the stat on the symlink itself." );
is( Test::MockFile::_mock_stat( 'stat',  '/broken_link' ), [],                    "stat on /broken_link is an empty array since what it points to doesn't exist." );

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
    ok( -d( $dir->path() ), 'Directory /quux exists' );
    ok( -d( $dir->path() . '/' ), 'Directory /quux/ also exists' );
}

done_testing();
exit;
