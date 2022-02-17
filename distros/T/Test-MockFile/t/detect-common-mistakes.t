#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile;

subtest(
    'Removing trailing forward slash for directories' => sub {
        my $dir0;
        ok(
            lives( sub { $dir0 = Test::MockFile->dir('/foo/'); } ),
            'Create /foo/',
        );

        isa_ok( $dir0, 'Test::MockFile' );
        is( $dir0->path(), '/foo', 'Trailing / is removed' );
    }
);

subtest(
    'Checking for multiple forward slash in paths' => sub {
        my $x = '';
        ok(
            lives( sub { $x = Test::MockFile->dir('/bar//')->path(); } ),
            'dir() successful',
        );

        is(
            $x,
            '/bar',
            'Double trailing forward slash',
        );

        $x = '';
        ok(
            lives( sub { $x = Test::MockFile->dir('/bar///')->path(); } ),

            'dir() succesful',
        );

        is(
            $x,
            '/bar',
            'Multiple trailing forward slash',
        );

        $x = '';
        ok(
            lives( sub { $x = Test::MockFile->dir('//bar/')->path(); } ),
            'dir() succesful',
        );

        is(
            $x,
            '/bar',
            'Double leading forward slash for dir',
        );

        $x = '';
        ok(
            lives( sub { $x = Test::MockFile->file( '//bar', '' )->path(); } ),
            'dir() succesful',
        );

        is(
            $x,
            '/bar',
            'Double leading forward slash for file',
        );

        $x = '';
        ok(
            lives( sub { $x = Test::MockFile->dir('/foo//bar/')->path(); } ),
            'dir() succesful',
        );

        is(
            $x,
            '/foo/bar',
            'Double forward slash in the middle for dir',
        );

        $x = '';
        ok(
            lives( sub { $x = Test::MockFile->file( '/foo//bar', '' )->path(); } ),
            'dir() succesful',
        );

        is(
            $x,
            '/foo/bar',
            'Double forward slash in the middle for file',
        );
    }
);

subtest(
    'Relative paths' => sub {
        is(
            lives( sub { Test::MockFile->dir('./bar/'); } ),
            1,
            'Success with ./ for dir',
        );

        is(
            lives( sub { Test::MockFile->file( './bar', [] ); } ),
            1,
            'Success with ./ for file',
        );

        like(
            dies( sub { Test::MockFile->dir('../bar/'); } ),
            qr/\QRelative paths are not supported\E/xms,
            'Failure with ../ for dir',
        );

        like(
            dies( sub { Test::MockFile->file( '../bar', [] ); } ),
            qr/\QRelative paths are not supported\E/xms,
            'Failure with ../ for file',
        );

        like(
            dies( sub { Test::MockFile->dir('/foo/../bar/'); } ),
            qr/\QRelative paths are not supported\E/xms,
            'Failure with /../ for dir',
        );

        is(
            lives( sub { Test::MockFile->file( '/foo/.', [] ); } ),
            1,
            'Success with /. for file',
        );

        like(
            dies( sub { Test::MockFile->file( '/foo/..', [] ); } ),
            qr/\QRelative paths are not supported\E/xms,
            'Failure with /.. for file',
        );

        like(
            dies( sub { Test::MockFile->file( '/foo/../bar', [] ); } ),
            qr/\QRelative paths are not supported\E/xms,
            'Failure with /../ for file',
        );

        is(
            lives( sub { Test::MockFile->dir('/foo/./bar/'); } ),
            1,
            'Success with /./ for dir',
        );

        is(
            lives( sub { Test::MockFile->file( '/foo/./bar', [] ); } ),
            1,
            'Success with /./ for file',
        );

        is(
            lives( sub { Test::MockFile->file( 'foo', [] ); } ),
            1,
            'No problem with current directory paths (file with trailing forward slash)',
        );

        is(
            lives( sub { Test::MockFile->dir('foo/'); } ),
            1,
            'No problem with current directory paths (dir with trailing forward slash)',
        );

        is(
            lives( sub { Test::MockFile->file( 'foo', [] ); } ),
            1,
            'No problem with current directory paths (dir with no trailing forward slash)',
        );
    }
);

done_testing();
exit;
