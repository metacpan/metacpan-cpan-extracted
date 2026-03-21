#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

note "-------------- read() tests --------------";

{
    my $file = Test::MockFile->file( '/read/basic', "hello world" );
    is( $file->read, "hello world", "read returns file contents in scalar context" );
}

{
    my $file = Test::MockFile->file( '/read/lines', "line1\nline2\nline3\n" );
    my @lines = $file->read;
    is( \@lines, [ "line1\n", "line2\n", "line3\n" ], "read returns lines in list context" );
}

{
    my $file = Test::MockFile->file( '/read/no-trailing', "line1\nline2" );
    my @lines = $file->read;
    is( \@lines, [ "line1\n", "line2" ], "read handles missing trailing newline" );
}

{
    my $file = Test::MockFile->file( '/read/empty', "" );
    is( $file->read, "", "read on empty file returns empty string" );
    my @lines = $file->read;
    is( \@lines, [], "read on empty file returns empty list" );
}

{
    my $file = Test::MockFile->file('/read/nonexistent');
    is( $file->read, undef, "read on non-existent file returns undef in scalar context" );
    my @lines = $file->read;
    is( \@lines, [], "read on non-existent file returns empty list" );
}

{
    my $file = Test::MockFile->file( '/read/single-line', "no newline" );
    my @lines = $file->read;
    is( \@lines, ["no newline"], "read with no newline gives single element list" );
}

{
    my $file = Test::MockFile->file( '/read/custom-sep', "aXXbXXc" );
    local $/ = "XX";
    my @lines = $file->read;
    is( \@lines, [ "aXX", "bXX", "c" ], "read respects custom \$/ separator" );
}

{
    my $file = Test::MockFile->file( '/read/slurp', "line1\nline2\n" );
    local $/ = undef;
    my @lines = $file->read;
    is( \@lines, ["line1\nline2\n"], "read with undef \$/ returns single element in list context" );
}

{
    my $dir = Test::MockFile->dir('/read/dir');
    like( dies { $dir->read }, qr/not supported for directories/, "read dies on directory" );
}

{
    my $link = Test::MockFile->symlink( '/somewhere', '/read/link' );
    like( dies { $link->read }, qr/not supported for symlinks/, "read dies on symlink" );
}

note "-------------- write() tests --------------";

{
    my $file = Test::MockFile->file( '/write/basic', "" );
    my $ret  = $file->write("new content");
    is( $file->contents, "new content", "write sets file contents" );
    is( $ret, object { prop blessed => 'Test::MockFile' }, "write returns the object" );
}

{
    my $file = Test::MockFile->file('/write/create');
    ok( !$file->exists, "file does not exist before write" );
    $file->write("created");
    ok( $file->exists,       "write brings non-existent file into existence" );
    is( $file->contents, "created", "contents are correct after write-create" );
}

{
    my $file = Test::MockFile->file( '/write/multi', "" );
    $file->write( "line1\n", "line2\n", "line3\n" );
    is( $file->contents, "line1\nline2\nline3\n", "write concatenates multiple args" );
}

{
    my $file = Test::MockFile->file( '/write/overwrite', "old" );
    $file->write("new");
    is( $file->contents, "new", "write overwrites existing contents" );
}

{
    my $file = Test::MockFile->file( '/write/empty', "stuff" );
    $file->write("");
    is( $file->contents, "", "write with empty string empties the file" );
}

{
    my $file = Test::MockFile->file( '/write/time', "before" );
    $file->mtime(1000);
    $file->ctime(1000);
    my $before = time;
    $file->write("after");
    ok( $file->mtime >= $before, "write updates mtime" );
    ok( $file->ctime >= $before, "write updates ctime" );
}

{
    my $dir = Test::MockFile->dir('/write/dir');
    like( dies { $dir->write("nope") }, qr/not supported for directories/, "write dies on directory" );
}

{
    my $link = Test::MockFile->symlink( '/somewhere', '/write/link' );
    like( dies { $link->write("nope") }, qr/not supported for symlinks/, "write dies on symlink" );
}

note "-------------- append() tests --------------";

{
    my $file = Test::MockFile->file( '/append/basic', "hello" );
    my $ret  = $file->append(" world");
    is( $file->contents, "hello world", "append adds to existing contents" );
    is( $ret, object { prop blessed => 'Test::MockFile' }, "append returns the object" );
}

{
    my $file = Test::MockFile->file('/append/create');
    ok( !$file->exists, "file does not exist before append" );
    $file->append("created");
    ok( $file->exists,       "append brings non-existent file into existence" );
    is( $file->contents, "created", "contents are correct after append-create" );
}

{
    my $file = Test::MockFile->file( '/append/multi', "start" );
    $file->append( "\n", "line2", "\n", "line3" );
    is( $file->contents, "start\nline2\nline3", "append concatenates multiple args" );
}

{
    my $file = Test::MockFile->file( '/append/time', "before" );
    $file->mtime(1000);
    $file->ctime(1000);
    my $before = time;
    $file->append(" after");
    ok( $file->mtime >= $before, "append updates mtime" );
    ok( $file->ctime >= $before, "append updates ctime" );
}

{
    my $file = Test::MockFile->file( '/append/empty', "stuff" );
    $file->append("");
    is( $file->contents, "stuff", "appending empty string is a no-op on contents" );
}

{
    my $dir = Test::MockFile->dir('/append/dir');
    like( dies { $dir->append("nope") }, qr/not supported for directories/, "append dies on directory" );
}

{
    my $link = Test::MockFile->symlink( '/somewhere', '/append/link' );
    like( dies { $link->append("nope") }, qr/not supported for symlinks/, "append dies on symlink" );
}

note "-------------- chaining tests --------------";

{
    my $file = Test::MockFile->file( '/chain/test', "" );
    $file->write("hello")->append(" world");
    is( $file->contents, "hello world", "write->append chaining works" );
}

done_testing();
