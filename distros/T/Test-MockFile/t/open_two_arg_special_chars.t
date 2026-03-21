#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Warnings qw( no_warnings );

use Test::MockFile qw< nostrict >;

# Two-arg open with filenames containing special characters.
# Previously, filenames with spaces, tildes, or other non-word characters
# would die with "Unsupported two-way open" instead of opening for read.

subtest '2-arg open with spaces in filename' => sub {
    my $path    = '/tmp/my file.txt';
    my $content = "hello world\n";
    my $mock    = Test::MockFile->file( $path, $content );

    my $fh;
    ok( lives { ok( open( $fh, $path ), "open succeeds" ) }, "no die on filename with spaces" );
    is( <$fh>, $content, "read content correctly" );
    close $fh;
};

subtest '2-arg open with @ in filename' => sub {
    my $path    = '/tmp/user@host.txt';
    my $content = "data\n";
    my $mock    = Test::MockFile->file( $path, $content );

    my $fh;
    ok( lives { ok( open( $fh, $path ), "open succeeds" ) }, "no die on filename with \@" );
    is( <$fh>, $content, "read content correctly" );
    close $fh;
};

subtest '2-arg open with parentheses in filename' => sub {
    my $path    = '/tmp/file (copy).txt';
    my $content = "copy data\n";
    my $mock    = Test::MockFile->file( $path, $content );

    my $fh;
    ok( lives { ok( open( $fh, $path ), "open succeeds" ) }, "no die on filename with parens" );
    is( <$fh>, $content, "read content correctly" );
    close $fh;
};

subtest '2-arg open with hash in filename' => sub {
    my $path    = '/tmp/issue#42.log';
    my $content = "log entry\n";
    my $mock    = Test::MockFile->file( $path, $content );

    my $fh;
    ok( lives { ok( open( $fh, $path ), "open succeeds" ) }, "no die on filename with #" );
    is( <$fh>, $content, "read content correctly" );
    close $fh;
};

subtest '2-arg open with equals and comma in filename' => sub {
    my $path    = '/tmp/key=value,other.conf';
    my $content = "config\n";
    my $mock    = Test::MockFile->file( $path, $content );

    my $fh;
    ok( lives { ok( open( $fh, $path ), "open succeeds" ) }, "no die on = and , in filename" );
    is( <$fh>, $content, "read content correctly" );
    close $fh;
};

subtest '2-arg write mode with special chars still works' => sub {
    my $path = '/tmp/out file.txt';
    my $mock = Test::MockFile->file( $path, '' );

    my $fh;
    ok( open( $fh, ">$path" ), "2-arg write open with spaces works" );
    print $fh "written";
    close $fh;
    is( $mock->contents, "written", "content was written" );
};

subtest '2-arg append mode with special chars still works' => sub {
    my $path = '/tmp/log (daily).txt';
    my $mock = Test::MockFile->file( $path, 'old ' );

    my $fh;
    ok( open( $fh, ">>$path" ), "2-arg append open with special chars works" );
    print $fh "new";
    close $fh;
    is( $mock->contents, "old new", "content was appended" );
};

subtest '2-arg open still passes through for unmocked files' => sub {
    # A path with special chars that is NOT mocked should fall through to CORE
    # (and fail since the file doesn't exist on disk)
    my $fh;
    my $ret = open( $fh, '/nonexistent/path with spaces/file.txt' );
    ok( !$ret, "2-arg open on unmocked special-char path returns false" );
};

done_testing();
