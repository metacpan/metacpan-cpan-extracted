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

is( Test::MockFile::_fh_to_file(),              undef,         "_fh_to_file()" );
is( Test::MockFile::_fh_to_file(0),             "$cwd/0",      "_fh_to_file(0)" );
is( Test::MockFile::_fh_to_file(''),            "$cwd/",       "_fh_to_file('')" );
is( Test::MockFile::_fh_to_file(' '),           "$cwd/ ",      "_fh_to_file(' ')" );
is( Test::MockFile::_fh_to_file('/etc/passwd'), '/etc/passwd', "_fh_to_file('/etc/passwd')" );

is( Test::MockFile::_fh_to_file($fh),  '/foo/bar', "_fh_to_file(\$fh)" );
is( Test::MockFile::_fh_to_file($fh2), '/bar/foo', "_fh_to_file(\$fh2)" );
close $fh;
close $fh2;
is( Test::MockFile::_fh_to_file($fh), undef, "_fh_to_file(\$fh) when closed." );

note "_find_file_or_fh";
push @mocked_files, Test::MockFile->symlink( '/foo/bar', '/abc' );
is( Test::MockFile::_find_file_or_fh('/abc'), '/abc', "_find_file_or_fh('/abc')" );
is( Test::MockFile::_find_file_or_fh( '/abc', 1 ), '/foo/bar', "_find_file_or_fh('/abc', 1) - follow" );

push @mocked_files, Test::MockFile->symlink( '/not/a/file', '/broken_link' );
like(
    dies { Test::MockFile::_find_file_or_fh( '/broken_link', 1 ) },
    qr{^Mocked file /broken_link points to unmocked file /not/a/file at },
    "_find_file_or_fh('/broken_link', 1) dies when /broken_link is mocked."
);

push @mocked_files, Test::MockFile->symlink( '/aaa', '/bbb' );
push @mocked_files, Test::MockFile->symlink( '/bbb', '/aaa' );
is( Test::MockFile::_find_file_or_fh( '/aaa', 1 ), [], "_find_file_or_fh('/aaaa', 1) - with circular links" );
is( $! + 0, ELOOP, '$! is ELOOP' );

note "_mock_stat";

is( Test::MockFile::_mock_stat( 'lstat', "/lib" ), FALLBACK_TO_REAL_OP(), "An unmocked file will return FALLBACK_TO_REAL_OP() to tell XS to handle it" );
like( dies { Test::MockFile::_mock_stat() }, qr/^_mock_stat called without a stat type at /, "no args fails cause we should have gotten a stat type." );
like( dies { Test::MockFile::_mock_stat( 'notastat', '' ) }, qr/^Unexpected stat type 'notastat' at /, "An unknown stat type fails cause this should never happen." );
is( Test::MockFile::_mock_stat( 'lstat', "" ),  FALLBACK_TO_REAL_OP(), "empty string passes to XS" );
is( Test::MockFile::_mock_stat( 'stat',  ' ' ), FALLBACK_TO_REAL_OP(), "A space string passes to XS" );

my $basic_stat_return = array {
    item 0;
    item 0;
    item 0100644;
    item 0;
    item 0;
    item 0;
    item 0;
    item 0;
    item match qr/^\d\d\d\d+$/;
    item match qr/^\d\d\d\d+$/;
    item match qr/^\d\d\d\d+$/;
    item 4096;
    item 0;
};

is( Test::MockFile::_mock_stat( 'lstat', '/foo/bar' ), $basic_stat_return, "/foo/bar mock stat" );
is( Test::MockFile::_mock_stat( 'stat', '/aaa' ), [], "/aaa mock stat when looped." );
is( $! + 0, ELOOP, "Throws an ELOOP error" );

push @mocked_files, Test::MockFile->file('/foo/baz');    # Missing file but mocked.
is( Test::MockFile::_mock_stat( 'lstat', '/foo/baz' ), [], "/foo/baz mock stat when missing." );

done_testing();
exit;
