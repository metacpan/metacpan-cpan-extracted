#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw/O_WRONLY O_CREAT O_APPEND O_RDWR/;

use Test::MockFile qw< nostrict >;

# POSIX specifies that creating a new file/directory sets atime, mtime,
# and ctime to the current time.  These tests verify that the mock
# timestamps reflect the operation time, not the mock construction time.

# Helper: set a mock's timestamps to a known past value so we can detect
# whether they were updated by the operation under test.
sub _set_timestamps_to_past {
    my ($mock) = @_;
    my $past = time - 100;
    $mock->{'atime'} = $past;
    $mock->{'mtime'} = $past;
    $mock->{'ctime'} = $past;
    return $past;
}

# ============================================================
# open() with > mode creating a new file
# ============================================================
subtest 'open > creates file: timestamps reset to now' => sub {
    my $mock = Test::MockFile->file('/tmp/test_create_gt');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( open( my $fh, '>', '/tmp/test_create_gt' ), 'open > succeeds' ) or diag "open: $!";
    close $fh;

    my @stat = stat('/tmp/test_create_gt');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# open() with >> mode creating a new file
# ============================================================
subtest 'open >> creates file: timestamps reset to now' => sub {
    my $mock = Test::MockFile->file('/tmp/test_create_append');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( open( my $fh, '>>', '/tmp/test_create_append' ), 'open >> succeeds' ) or diag "open: $!";
    close $fh;

    my @stat = stat('/tmp/test_create_append');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# open() with +> mode creating a new file
# ============================================================
subtest 'open +> creates file: timestamps reset to now' => sub {
    my $mock = Test::MockFile->file('/tmp/test_create_rw_trunc');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( open( my $fh, '+>', '/tmp/test_create_rw_trunc' ), 'open +> succeeds' ) or diag "open: $!";
    close $fh;

    my @stat = stat('/tmp/test_create_rw_trunc');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# open() with +>> mode creating a new file
# ============================================================
subtest 'open +>> creates file: timestamps reset to now' => sub {
    my $mock = Test::MockFile->file('/tmp/test_create_rw_append');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( open( my $fh, '+>>', '/tmp/test_create_rw_append' ), 'open +>> succeeds' ) or diag "open: $!";
    close $fh;

    my @stat = stat('/tmp/test_create_rw_append');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# open() with > truncating an existing file
# Truncation should update mtime/ctime but NOT atime.
# ============================================================
subtest 'open > truncating existing file: mtime/ctime updated, atime unchanged' => sub {
    my $mock = Test::MockFile->file( '/tmp/test_trunc', 'hello' );
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( open( my $fh, '>', '/tmp/test_trunc' ), 'open > succeeds on existing file' ) or diag "open: $!";
    close $fh;

    my @stat = stat('/tmp/test_trunc');
    is( $stat[8],  $past, 'atime unchanged on truncation' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime updated on truncation' );
    cmp_ok( $stat[10], '>=', $before, 'ctime updated on truncation' );
};

# ============================================================
# sysopen() with O_CREAT creating a new file
# ============================================================
subtest 'sysopen O_CREAT creates file: timestamps reset to now' => sub {
    my $mock = Test::MockFile->file('/tmp/test_sysopen_create');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( sysopen( my $fh, '/tmp/test_sysopen_create', O_WRONLY | O_CREAT ), 'sysopen O_CREAT succeeds' ) or diag "sysopen: $!";
    close $fh;

    my @stat = stat('/tmp/test_sysopen_create');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# sysopen() with O_CREAT|O_APPEND creating a new file
# ============================================================
subtest 'sysopen O_CREAT|O_APPEND creates file: timestamps reset to now' => sub {
    my $mock = Test::MockFile->file('/tmp/test_sysopen_creat_append');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( sysopen( my $fh, '/tmp/test_sysopen_creat_append', O_WRONLY | O_CREAT | O_APPEND ), 'sysopen O_CREAT|O_APPEND succeeds' ) or diag "sysopen: $!";
    close $fh;

    my @stat = stat('/tmp/test_sysopen_creat_append');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# mkdir() creating a new directory
# ============================================================
subtest 'mkdir creates directory: timestamps reset to now' => sub {
    my $mock = Test::MockFile->dir('/tmp/test_mkdir_ts');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( mkdir('/tmp/test_mkdir_ts'), 'mkdir succeeds' ) or diag "mkdir: $!";

    my @stat = stat('/tmp/test_mkdir_ts');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
    cmp_ok( $stat[8],  '>', $past,    'atime updated from past value' );
};

# ============================================================
# mkdir() with custom permissions: timestamps still reset
# ============================================================
subtest 'mkdir with perms creates directory: timestamps reset to now' => sub {
    my $mock = Test::MockFile->dir('/tmp/test_mkdir_perms_ts');
    my $past = _set_timestamps_to_past($mock);

    my $before = time;
    ok( mkdir( '/tmp/test_mkdir_perms_ts', 0755 ), 'mkdir with perms succeeds' ) or diag "mkdir: $!";

    my @stat = stat('/tmp/test_mkdir_perms_ts');
    cmp_ok( $stat[8],  '>=', $before, 'atime >= operation time' );
    cmp_ok( $stat[9],  '>=', $before, 'mtime >= operation time' );
    cmp_ok( $stat[10], '>=', $before, 'ctime >= operation time' );
};

done_testing();
