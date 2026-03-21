#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< dies lives >;

use Cwd   ();
use Errno  qw< ENOENT >;

# Create real tempfiles before Test::MockFile overrides are installed.
# We avoid File::Temp because its DESTROY can trigger overridden chmod
# on older Perls, causing spurious warnings.
my ( $passthrough_tempfile, $nostrict_tempfile, $mixed_tempfile );
BEGIN {
    $passthrough_tempfile = "/tmp/tmf_utime_pass_$$.tmp";
    $nostrict_tempfile    = "/tmp/tmf_utime_nostrict_$$.tmp";
    $mixed_tempfile       = "/tmp/tmf_utime_mixed_$$.tmp";
    CORE::open( my $fh1, '>', $passthrough_tempfile ) or die "Cannot create $passthrough_tempfile: $!";
    CORE::close($fh1);
    CORE::open( my $fh2, '>', $nostrict_tempfile ) or die "Cannot create $nostrict_tempfile: $!";
    CORE::close($fh2);
    CORE::open( my $fh3, '>', $mixed_tempfile ) or die "Cannot create $mixed_tempfile: $!";
    CORE::close($fh3);
}

use Test::MockFile qw< nostrict >;

subtest(
    'utime on mocked file' => sub {
        my $file = Test::MockFile->file( '/foo/bar', 'content' );
        ok( -f '/foo/bar', 'File exists' );

        my $new_atime = 1000000;
        my $new_mtime = 2000000;

        is( utime( $new_atime, $new_mtime, '/foo/bar' ), 1, 'utime returns 1 for success' );

        my @stat = stat('/foo/bar');
        is( $stat[8], $new_atime, 'atime was updated' );
        is( $stat[9], $new_mtime, 'mtime was updated' );
    }
);

subtest(
    'utime updates ctime to current time' => sub {
        my $file = Test::MockFile->file( '/foo/baz', 'content' );

        my $before = time;
        utime( 1000, 2000, '/foo/baz' );
        my $after = time;

        my @stat = stat('/foo/baz');
        ok( $stat[10] >= $before && $stat[10] <= $after, 'ctime was updated to current time' );
    }
);

subtest(
    'utime with undef uses current time' => sub {
        my $file = Test::MockFile->file( '/foo/undef_test', 'content' );

        my $before = time;
        is( utime( undef, undef, '/foo/undef_test' ), 1, 'utime with undef returns 1' );
        my $after = time;

        my @stat = stat('/foo/undef_test');
        ok( $stat[8] >= $before && $stat[8] <= $after, 'atime set to current time when undef' );
        ok( $stat[9] >= $before && $stat[9] <= $after, 'mtime set to current time when undef' );
    }
);

subtest(
    'utime on multiple mocked files' => sub {
        my $file1 = Test::MockFile->file( '/multi/a', 'aaa' );
        my $file2 = Test::MockFile->file( '/multi/b', 'bbb' );

        is( utime( 5000, 6000, '/multi/a', '/multi/b' ), 2, 'utime returns 2 for two files' );

        my @stat_a = stat('/multi/a');
        my @stat_b = stat('/multi/b');
        is( $stat_a[8], 5000, 'file a atime updated' );
        is( $stat_a[9], 6000, 'file a mtime updated' );
        is( $stat_b[8], 5000, 'file b atime updated' );
        is( $stat_b[9], 6000, 'file b mtime updated' );
    }
);

subtest(
    'utime on nonexistent mocked file' => sub {
        my $file = Test::MockFile->file('/no/exist');
        ok( !-f '/no/exist', 'File does not exist' );

        $! = 0;
        is( utime( 1000, 2000, '/no/exist' ), 0, 'utime returns 0 for nonexistent file' );
        is( $! + 0, ENOENT, '$! is set to ENOENT' );
    }
);

subtest(
    'utime on mocked directory' => sub {
        my $dir = Test::MockFile->dir('/mydir');
        ok( mkdir('/mydir'), 'Created directory' );
        ok( -d '/mydir',     'Directory exists' );

        is( utime( 3000, 4000, '/mydir' ), 1, 'utime on directory returns 1' );

        my @stat = stat('/mydir');
        is( $stat[8], 3000, 'dir atime updated' );
        is( $stat[9], 4000, 'dir mtime updated' );
    }
);

subtest(
    'utime with no files returns 0' => sub {
        is( utime( 1000, 2000 ), 0, 'utime with no files returns 0' );
    }
);

subtest(
    'utime on mix of mocked and unmocked files' => sub {
        my $mock = Test::MockFile->file( '/mocked/mixed_test', 'data' );

        my $new_atime = 7000000;
        my $new_mtime = 8000000;

        is( utime( $new_atime, $new_mtime, '/mocked/mixed_test', $mixed_tempfile ), 2,
            'utime returns 2 for mixed mocked/unmocked' );

        # Verify mocked file was updated
        my @mock_stat = stat('/mocked/mixed_test');
        is( $mock_stat[8], $new_atime, 'mocked file atime updated' );
        is( $mock_stat[9], $new_mtime, 'mocked file mtime updated' );

        # Verify unmocked file was updated via CORE::utime passthrough
        my @real_stat = CORE::stat($mixed_tempfile);
        is( $real_stat[8], $new_atime, 'unmocked file atime updated' );
        is( $real_stat[9], $new_mtime, 'unmocked file mtime updated' );
    }
);

subtest(
    'utime on unmocked file passes through' => sub {
        my $new_atime = 1000000;
        my $new_mtime = 2000000;

        is( utime( $new_atime, $new_mtime, $passthrough_tempfile ), 1, 'utime on real file returns 1' );

        my @stat = CORE::stat($passthrough_tempfile);
        is( $stat[8], $new_atime, 'real file atime was updated' );
        is( $stat[9], $new_mtime, 'real file mtime was updated' );

        CORE::unlink $passthrough_tempfile;
    }
);

subtest(
    'utime on unmocked file while mocked files exist' => sub {
        my $mock = Test::MockFile->file( '/mocked/for_utime', 'data' );

        my $new_atime = 3000000;
        my $new_mtime = 4000000;

        is( utime( $new_atime, $new_mtime, $nostrict_tempfile ), 1, 'utime on unmocked file returns 1' );

        my @stat = CORE::stat($nostrict_tempfile);
        is( $stat[8], $new_atime, 'unmocked file atime was updated' );
        is( $stat[9], $new_mtime, 'unmocked file mtime was updated' );

        CORE::unlink $nostrict_tempfile;
    }
);

# Reference test: verify real utime behavior with mixed existing/non-existing files.
# This demonstrates what CORE::utime does so our mock can match it.
subtest(
    'real utime with mixed existing/non-existing files sets ENOENT' => sub {
        my $nonexistent = "/tmp/tmf_utime_DOES_NOT_EXIST_$$.tmp";

        # Sanity: the non-existent file really doesn't exist
        ok( !-e $nonexistent, 'non-existent file does not exist' );

        $! = 0;
        my $changed = CORE::utime( 1000, 2000, $mixed_tempfile, $nonexistent );

        is( $changed, 1, 'CORE::utime returns 1 (only the existing file succeeded)' );
        is( $! + 0, ENOENT, 'CORE::utime sets $! to ENOENT for the missing file' );

        # The existing file was still updated despite the other file failing
        my @stat = CORE::stat($mixed_tempfile);
        is( $stat[8], 1000, 'existing file atime was updated' );
        is( $stat[9], 2000, 'existing file mtime was updated' );

        CORE::unlink $mixed_tempfile;
    }
);

# Mock test: verify our mock matches real utime behavior for mixed exist/non-exist
subtest(
    'mocked utime on mix of existing and non-existing mocked files' => sub {
        my $exists     = Test::MockFile->file( '/mixed/exists',     'content' );
        my $not_exists = Test::MockFile->file( '/mixed/not_exists' );    # undef = does not exist

        ok( -f '/mixed/exists',      'existing mock is a file' );
        ok( !-f '/mixed/not_exists', 'non-existing mock does not exist' );

        $! = 0;
        my $changed = utime( 5000, 6000, '/mixed/exists', '/mixed/not_exists' );

        is( $changed, 1, 'utime returns 1 (only existing file succeeded)' );
        is( $! + 0, ENOENT, '$! is ENOENT for the non-existing mocked file' );

        # The existing mock was still updated
        my @stat = stat('/mixed/exists');
        is( $stat[8], 5000, 'existing mock atime was updated' );
        is( $stat[9], 6000, 'existing mock mtime was updated' );
    }
);

done_testing();
exit;
