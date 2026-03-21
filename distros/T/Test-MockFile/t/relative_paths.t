#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOTEMPTY ENOENT/;
use Cwd ();

use Test::MockFile qw< nostrict >;

my $cwd = Cwd::getcwd();

# All mocks are registered under absolute paths in %files_being_mocked.
# Operations that receive relative paths from user code must resolve them
# before doing hash lookups or parent-dir timestamp updates.

note "-------------- rmdir: relative path still enforces ENOTEMPTY --------------";
{
    my $dir   = Test::MockFile->new_dir("$cwd/reldir");
    my $child = Test::MockFile->file( "$cwd/reldir/child.txt", 'data' );

    ok( !rmdir('reldir'), 'rmdir with relative path fails on non-empty dir' );
    my $errno = $! + 0;
    is( $errno, ENOTEMPTY, 'errno is ENOTEMPTY for relative rmdir' );
    ok( $dir->exists,   'directory still exists after failed rmdir' );
    ok( $child->exists, 'child still exists after failed rmdir' );
}

note "-------------- rmdir: relative path succeeds on empty dir --------------";
{
    my $dir = Test::MockFile->new_dir("$cwd/emptyrel");

    ok( rmdir('emptyrel'), 'rmdir with relative path succeeds on empty dir' );
    ok( !$dir->exists, 'directory removed after rmdir' );
}

note "-------------- rmdir: relative path updates parent dir timestamps --------------";
{
    my $parent = Test::MockFile->new_dir($cwd);
    my $dir    = Test::MockFile->new_dir("$cwd/tsdir");

    # Set parent timestamps to the past
    $parent->{'mtime'} = 1000;
    $parent->{'ctime'} = 1000;

    my $before = time;
    ok( rmdir('tsdir'), 'rmdir with relative path succeeds' );

    ok( $parent->{'mtime'} >= $before, 'parent mtime updated after relative rmdir' );
    ok( $parent->{'ctime'} >= $before, 'parent ctime updated after relative rmdir' );
}

note "-------------- mkdir: relative path updates parent dir timestamps --------------";
{
    my $parent = Test::MockFile->new_dir($cwd);
    my $dir    = Test::MockFile->dir("$cwd/newrel");

    # Set parent timestamps to the past
    $parent->{'mtime'} = 1000;
    $parent->{'ctime'} = 1000;

    my $before = time;
    ok( mkdir('newrel'), 'mkdir with relative path succeeds' );

    ok( $parent->{'mtime'} >= $before, 'parent mtime updated after relative mkdir' );
    ok( $parent->{'ctime'} >= $before, 'parent ctime updated after relative mkdir' );
}

note "-------------- rename: relative paths update parent dir timestamps --------------";
{
    my $parent = Test::MockFile->new_dir($cwd);
    my $old    = Test::MockFile->file( "$cwd/rensrc", 'content' );
    my $new    = Test::MockFile->file("$cwd/rendst");

    $parent->{'mtime'} = 1000;
    $parent->{'ctime'} = 1000;

    my $before = time;
    ok( rename( 'rensrc', 'rendst' ), 'rename with relative paths succeeds' );

    ok( $parent->{'mtime'} >= $before, 'parent mtime updated after relative rename' );
    ok( $parent->{'ctime'} >= $before, 'parent ctime updated after relative rename' );
    is( $new->contents, 'content', 'renamed file has correct contents' );
}

done_testing();
