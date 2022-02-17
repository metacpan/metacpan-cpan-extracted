#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test2::Tools::Warnings qw< warning >;
use Test::MockFile qw< nostrict >;

my $filename = __FILE__;
my $file     = Test::MockFile->file( $filename, 'whatevs' );

subtest(
    'Defaults' => sub {
        my $dir_foo  = Test::MockFile->dir('/foo');
        my $file_bar = Test::MockFile->file( '/foo/bar', 'content' );

        ok( -d '/foo',     'Directory /foo exists' );
        ok( -f '/foo/bar', 'File /foo/bar exists' );

        my $dir_def_perm = sprintf '%04o', 0777 - umask;
        is(
            sprintf( '%04o', ( stat '/foo' )[2] & 07777 ),
            $dir_def_perm,
            "Directory /foo is set to $dir_def_perm",
        );

        # These variables are for debugging test failures
        my $umask         = sprintf '%04o', umask;
        my $perms_before  = sprintf '%04o', Test::MockFile::S_IFPERMS() & 0666;
        my $perms_after_1 = sprintf '%04o', ( Test::MockFile::S_IFPERMS() & 0666 ) ^ umask;
        my $perms_after_2 = sprintf '%04o', ( ( Test::MockFile::S_IFPERMS() & 0666 ) ^ umask ) | Test::MockFile::S_IFREG();

        my $file_def_perm = sprintf '%04o', 0666 - umask;
        is(
            sprintf( '%04o', ( stat '/foo/bar' )[2] & 07777 ),
            $file_def_perm,
            "File /foo/bar is set to $file_def_perm (umask: $umask, perms before: $perms_before, perms after 1: $perms_after_1, perms after 2: $perms_after_2)",
        );
    }
);

subtest(
    'Changing mode (real vs. mocked)' => sub {
        ok( CORE::mkdir('fooz'),         'Successfully created real directory' );
        ok( CORE::chmod( 0600, 'fooz' ), 'Successfully chmod\'ed real directory' );
        is(
            sprintf( '%04o', ( CORE::stat('fooz') )[2] & 07777 ),
            '0600',
            'CORE::chmod() set the perms correctly',
        );
        ok( CORE::rmdir('fooz'), 'Successfully deleted real directory' );

        my $dir_foo  = Test::MockFile->dir('/foo');
        my $file_bar = Test::MockFile->file( '/foo/bar', 'content' );

        ok( -d '/foo',     'Directory /foo exists' );
        ok( -f '/foo/bar', 'File /foo/bar exists' );

        chmod 0600, qw< /foo /foo/bar >;

        is(
            sprintf( '%04o', ( stat '/foo' )[2] & 07777 ),
            '0600',
            'Directory /foo is now set to 0600',
        );

        is(
            sprintf( '%04o', ( stat '/foo/bar' )[2] & 07777 ),
            '0600',
            'File /foo/bar is now set to 0600',
        );

        chmod 0777, qw< /foo /foo/bar >;

        is(
            sprintf( '%04o', ( stat '/foo' )[2] & 07777 ),
            '0777',
            'Directory /foo is now set to 0600',
        );

        is(
            sprintf( '%04o', ( stat '/foo/bar' )[2] & 07777 ),
            '0777',
            'File /foo/bar is now set to 0600',
        );
    }
);

subtest(
    'Providing a string as mode mask' => sub {
        ok( CORE::mkdir('fooz'), 'Successfully created real directory' );

        my $core_chmod_res;

        like(
            warning( sub { $core_chmod_res = CORE::chmod( 'hello', 'fooz' ) } ),
            qr/^\QArgument "hello" isn't numeric in chmod\E/xms,
            'CORE::chmod() threw a warning when trying to numify',
        );

        ok( $core_chmod_res, 'Successfully chmod\'ed real directory' );

        is( $!, '', 'No observed error' );
        is(
            sprintf( '%04o', ( CORE::stat('fooz') )[2] & 07777 ),
            '0000',
            'CORE::chmod() set the perms correctly',
        );

        ok( CORE::rmdir('fooz'), 'Successfully deleted real directory' );

        # --- Mock ---

        my $dir_foo = Test::MockFile->dir('/foo');

        ok( !-d '/foo', 'Directory /foo does not exist' );

        # If we don't zero this out, nothing else will - wtf?
        $! = 0;

        ok( mkdir('/foo'), 'Successfully created mocked directory' );
        ok( -d '/foo',     'Directory /foo now exists' );

        my $chmod_res;
        like(
            warning( sub { $chmod_res = chmod 'hello', '/foo' } ),
            qr/^\QArgument "hello" isn't numeric in chmod\E/xms,
            'chmod() threw a warning when trying to numify',
        );

        ok( $chmod_res, 'Successfully chmod\'ed real directory' );

        is( $!, '', 'No observed error' );
        is(
            sprintf( '%04o', ( CORE::stat('/foo') )[2] & 07777 ),
            '0000',
            'chmod() set the perms correctly',
        );

        ok( rmdir('/foo'), 'Successfully deleted real directory' );
        ok( !-d '/foo',    'Directory /foo no longer exist' );
    }
);

done_testing();
exit;
