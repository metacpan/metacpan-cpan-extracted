#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Errno qw/ENOENT EISDIR/;

use Test::MockFile qw< nostrict >;

# IO::File is loaded by Test::MockFile itself, so it's available.
# The key issue: IO::File::open() uses CORE::open which bypasses CORE::GLOBAL::open.

note "-------------- IO::File->new with mocked file --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_test', "hello world\n" );

    my $fh = IO::File->new( '/fake/iofile_test', 'r' );
    ok( defined $fh, "IO::File->new opens a mocked file" );
    if ($fh) {
        my $line = <$fh>;
        is( $line, "hello world\n", " ... reads correct content" );
        is( <$fh>, undef,           " ... EOF" );
        $fh->close;
    }
}

note "-------------- IO::File->new read mode (default) --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_default', "line1\nline2\n" );

    my $fh = IO::File->new('/fake/iofile_default');
    ok( defined $fh, "IO::File->new with bare filename opens mocked file" );
    if ($fh) {
        my @lines = <$fh>;
        is_deeply( \@lines, [ "line1\n", "line2\n" ], " ... reads all lines" );
        $fh->close;
    }
}

note "-------------- IO::File->new with explicit read mode '<' --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_read', "content here\n" );

    my $fh = IO::File->new( '/fake/iofile_read', '<' );
    ok( defined $fh, "IO::File->new with '<' mode opens mocked file" );
    if ($fh) {
        my $line = <$fh>;
        is( $line, "content here\n", " ... reads correct content" );
        $fh->close;
    }
}

note "-------------- IO::File->new with write mode 'w' --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_write', '' );

    my $fh = IO::File->new( '/fake/iofile_write', 'w' );
    ok( defined $fh, "IO::File->new with 'w' mode opens mocked file" );
    if ($fh) {
        print $fh "written via IO::File\n";
        $fh->close;
    }

    is( $mock->contents(), "written via IO::File\n", " ... content was written to mock" );
}

note "-------------- IO::File->new with append mode 'a' --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_append', "existing\n" );

    my $fh = IO::File->new( '/fake/iofile_append', 'a' );
    ok( defined $fh, "IO::File->new with 'a' mode opens mocked file" );
    if ($fh) {
        print $fh "appended\n";
        $fh->close;
    }

    is( $mock->contents(), "existing\nappended\n", " ... content was appended" );
}

note "-------------- IO::File->new with read-write mode 'r+' --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_rw', "original\n" );

    my $fh = IO::File->new( '/fake/iofile_rw', 'r+' );
    ok( defined $fh, "IO::File->new with 'r+' mode opens mocked file" );
    if ($fh) {
        my $line = <$fh>;
        is( $line, "original\n", " ... reads existing content" );
        $fh->close;
    }
}

note "-------------- IO::File->new on non-existent mock --------------";
{
    my $mock = Test::MockFile->file('/fake/iofile_noexist');

    my $fh = IO::File->new( '/fake/iofile_noexist', 'r' );
    ok( !defined $fh, "IO::File->new returns undef for non-existent mock" );
}

note "-------------- IO::File->new with numeric sysopen mode --------------";
{
    use Fcntl qw/O_RDONLY O_WRONLY O_CREAT O_TRUNC/;

    my $mock = Test::MockFile->file( '/fake/iofile_sysopen', "sysopen data\n" );

    my $fh = IO::File->new( '/fake/iofile_sysopen', O_RDONLY );
    ok( defined $fh, "IO::File->new with O_RDONLY opens mocked file" );
    if ($fh) {
        my $line = <$fh>;
        is( $line, "sysopen data\n", " ... reads correct content via sysopen" );
        $fh->close;
    }
}

note "-------------- IO::File->open method on existing object --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_method', "method test\n" );

    my $fh = IO::File->new;
    ok( defined $fh, "IO::File->new creates empty handle" );

    my $result = $fh->open( '/fake/iofile_method', 'r' );
    ok( $result, " ... open method succeeds on mocked file" );
    if ($result) {
        my $line = <$fh>;
        is( $line, "method test\n", " ... reads correct content" );
        $fh->close;
    }
}

note "-------------- IO::File with 2-arg embedded mode --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_2arg', '' );

    my $fh = IO::File->new('>/fake/iofile_2arg');
    ok( defined $fh, "IO::File->new with '>/path' opens mocked file for write" );
    if ($fh) {
        print $fh "two-arg write\n";
        $fh->close;
    }

    is( $mock->contents(), "two-arg write\n", " ... content was written" );
}

note "-------------- IO::File with write+truncate via sysopen mode --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_trunc', "old data" );

    my $fh = IO::File->new( '/fake/iofile_trunc', O_WRONLY | O_TRUNC );
    ok( defined $fh, "IO::File->new with O_WRONLY|O_TRUNC opens mocked file" );
    if ($fh) {
        print $fh "new";
        $fh->close;
    }

    is( $mock->contents(), "new", " ... old content was truncated" );
}

note "-------------- IO::File getline method on mocked file --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_getline', "first\nsecond\nthird\n" );

    my $fh = IO::File->new( '/fake/iofile_getline', 'r' );
    ok( defined $fh, "IO::File->new opens for getline test" );
    if ($fh) {
        is( $fh->getline, "first\n",  " ... getline returns first line" );
        is( $fh->getline, "second\n", " ... getline returns second line" );
        is( $fh->getline, "third\n",  " ... getline returns third line" );
        is( $fh->getline, undef,      " ... getline returns undef at EOF" );
        $fh->close;
    }
}

note "-------------- IO::File->new on directory mock returns EISDIR --------------";
{
    my $dir = Test::MockFile->dir('/fake/iofile_dir');
    mkdir '/fake/iofile_dir';

    $! = 0;
    my $fh = IO::File->new( '/fake/iofile_dir', 'r' );
    ok( !defined $fh, "IO::File->new on a directory returns undef" );
    is( $! + 0, EISDIR, " ... errno is EISDIR" );
}

note "-------------- IO::File->new on directory mock via sysopen returns EISDIR --------------";
{
    use Fcntl qw/O_RDONLY/;

    my $dir = Test::MockFile->dir('/fake/iofile_dir_sys');
    mkdir '/fake/iofile_dir_sys';

    $! = 0;
    my $fh = IO::File->new( '/fake/iofile_dir_sys', O_RDONLY );
    ok( !defined $fh, "IO::File->new with O_RDONLY on a directory returns undef" );
    is( $! + 0, EISDIR, " ... errno is EISDIR" );
}

note "-------------- IO::File append mode preserves append semantics after seek --------------";
{
    my $mock = Test::MockFile->file( '/fake/iofile_append_seek', "AAA" );

    my $fh = IO::File->new( '/fake/iofile_append_seek', 'a' );
    ok( defined $fh, "IO::File->new with 'a' mode opens mocked file" );
    if ($fh) {
        # Write something in append mode
        print $fh "BBB";
        is( $mock->contents(), "AAABBB", " ... first append works" );

        # Seek to beginning and write again — should still append
        seek $fh, 0, 0;
        print $fh "CCC";
        is( $mock->contents(), "AAABBBCCC", " ... append after seek still appends" );

        $fh->close;
    }
}

done_testing();
