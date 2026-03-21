#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test2::Tools::Warnings qw< warning >;
use Test::MockFile qw< nostrict >;
use Errno qw/ENOENT/;

use File::Temp qw< tempfile >;

my $filename = __FILE__;
my $file     = Test::MockFile->file( $filename, 'whatevs' );

subtest(
    'Defaults' => sub {
        my $dir_foo  = Test::MockFile->dir('/foo');
        my $file_bar = Test::MockFile->file( '/foo/bar', 'content' );

        ok( -d '/foo',     'Directory /foo exists' );
        ok( -f '/foo/bar', 'File /foo/bar exists' );

        my $dir_def_perm = sprintf '%04o', 0777 & ~umask;
        is(
            sprintf( '%04o', ( stat '/foo' )[2] & 07777 ),
            $dir_def_perm,
            "Directory /foo is set to $dir_def_perm",
        );

        # These variables are for debugging test failures
        my $umask         = sprintf '%04o', umask;
        my $perms_before  = sprintf '%04o', Test::MockFile::S_IFPERMS() & 0666;
        my $perms_after_1 = sprintf '%04o', ( Test::MockFile::S_IFPERMS() & 0666 ) & ~umask;
        my $perms_after_2 = sprintf '%04o', ( ( Test::MockFile::S_IFPERMS() & 0666 ) & ~umask ) | Test::MockFile::S_IFREG();

        my $file_def_perm = sprintf '%04o', 0666 & ~umask;
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
    'Changing mode filehandle' => sub {
      SKIP: {

            if ( $^V lt 5.28.0 ) {
                skip "Skipped: need Perl >= 5.28.0", 1;
                return;
            }

            my $test_string = "abcd\nefgh\n";
            my ( $fh_real, $filename ) = tempfile();
            print $fh_real $test_string;
            {
                note "-------------- REAL MODE --------------";
                ok chmod( 0700, $filename ), 'chmod on file';
                open( my $fh, '>', $filename );
                ok chmod( 0711, $fh ), 'chmod on filehandle';
            }

            {
                note "-------------- MOCK MODE --------------";
                my $bar = Test::MockFile->file( $filename, $test_string );
                ok chmod( 0700, $filename ), 'chmod on file';
                open( my $fh, '>', $filename );
                ok chmod( 0711, $fh ), 'chmod on filehandle';
            }

        }

        return;
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

subtest(
    'File creation with non-default mode applies umask correctly' => sub {
        # With umask 0022, creating a file with mode 0644 should stay 0644
        # (bits already clear). With the old XOR bug, 0644 ^ 0022 = 0666.
        my $file = Test::MockFile->file( '/umask_test/file', 'data', { mode => 0644 } );

        my $expected = sprintf '%04o', 0644 & ~umask;
        is(
            sprintf( '%04o', ( stat '/umask_test/file' )[2] & 07777 ),
            $expected,
            "File with explicit mode 0644 gets $expected after umask",
        );
    }
);

subtest(
    'chmod method ignores umask' => sub {
        my $file = Test::MockFile->file( '/chmod_umask/file', 'content' );

        # Real chmod(2) ignores umask — setting 0755 should give exactly 0755
        $file->chmod(0755);
        is(
            sprintf( '%04o', ( stat '/chmod_umask/file' )[2] & 07777 ),
            '0755',
            'chmod(0755) gives exactly 0755 (umask not applied)',
        );

        $file->chmod(0644);
        is(
            sprintf( '%04o', ( stat '/chmod_umask/file' )[2] & 07777 ),
            '0644',
            'chmod(0644) gives exactly 0644 (umask not applied)',
        );
    }
);

subtest(
    'mkdir with non-default mode applies umask correctly' => sub {
        # mkdir(path, 0700) with umask 0022 should give 0700 (bits already clear)
        # With the old XOR bug, 0700 ^ 0022 = 0722
        my $dir = Test::MockFile->dir('/umask_mkdir');

        my $expected = sprintf '%04o', 0700 & ~umask;
        ok( mkdir( '/umask_mkdir', 0700 ), 'mkdir with mode 0700' );
        is(
            sprintf( '%04o', ( stat '/umask_mkdir' )[2] & 07777 ),
            $expected,
            "mkdir(0700) gives $expected after umask",
        );
    }
);

subtest(
    'chmod masks mode to S_IFPERMS (high bits do not corrupt file type)' => sub {
        my $file = Test::MockFile->file( '/chmod_mask/file', 'data' );
        my $dir  = Test::MockFile->dir('/chmod_mask');

        # Passing file type bits (e.g. S_IFREG=0100000) should not corrupt
        # the stored mode. CORE::chmod silently ignores bits above 07777.
        chmod 0100755, '/chmod_mask/file';
        my $got_perms = ( stat '/chmod_mask/file' )[2] & 07777;
        is(
            sprintf( '%04o', $got_perms ),
            '0755',
            'chmod with S_IFREG bits gives 0755, not corrupted mode',
        );

        ok( -f '/chmod_mask/file', 'File type preserved after chmod with high bits' );

        # Same test for directory
        chmod 0100700, '/chmod_mask';
        my $dir_perms = ( stat '/chmod_mask' )[2] & 07777;
        is(
            sprintf( '%04o', $dir_perms ),
            '0700',
            'chmod on dir with high bits gives 0700',
        );

        ok( -d '/chmod_mask', 'Directory type preserved after chmod with high bits' );
    }
);

subtest(
    'chmod with broken symlink in multi-file list does not confess' => sub {
        my $link = Test::MockFile->symlink( '/nonexistent_target', '/chmod_broken_link' );
        my $file = Test::MockFile->file( '/chmod_real_file', 'content' );

        # chmod on a mix of regular file + broken symlink should NOT die.
        # The broken symlink should silently fail with ENOENT, and the
        # regular file should succeed.
        my ( $result, $errno );
        ok(
            lives { $result = chmod( 0755, '/chmod_broken_link', '/chmod_real_file' ); $errno = $! + 0 },
            'chmod with broken symlink + regular file does not confess',
        );
        is( $result, 1, 'chmod returns 1 (one file changed)' );
        is( $errno, ENOENT, 'errno set to ENOENT for the broken symlink' );
    }
);

subtest(
    'chmod with only broken symlink' => sub {
        my $link = Test::MockFile->symlink( '/nowhere', '/chmod_only_broken' );

        my ( $result, $errno );
        ok(
            lives { $result = chmod( 0755, '/chmod_only_broken' ); $errno = $! + 0 },
            'chmod with only a broken symlink does not confess',
        );
        is( $result, 0, 'chmod returns 0 (no files changed)' );
        is( $errno, ENOENT, 'errno set to ENOENT' );
    }
);

done_testing();
exit;
