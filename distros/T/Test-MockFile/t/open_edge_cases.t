#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT ENOTDIR ELOOP/;

use Test::MockFile qw< nostrict >;

# ============================================================
# Test: 2-arg open with +>> mode (read-write append)
# Bug: regex ( >> | [+]?> | [+]?< ) matches +> before +>>
# ============================================================
subtest '+>> two-arg open mode parsing' => sub {
    my $mock = Test::MockFile->file( '/tmp/append_test', 'original' );

    # +>> should open for read-write append, like 3-arg open($fh, '+>>', $file)
    ok( open( my $fh, '+>>/tmp/append_test' ), 'open with +>> two-arg succeeds' ) or diag "open failed: $!";

    # Append some content
    print $fh "appended";
    close $fh;

    is( $mock->contents, 'originalappended', '+>> appends to existing content' );
};

subtest '+>> on new file creates it' => sub {
    my $mock = Test::MockFile->file('/tmp/append_new');

    # +>> on non-existent file should create it
    ok( open( my $fh, '+>>/tmp/append_new' ), '+>> creates non-existent file' ) or diag "open failed: $!";

    print $fh "hello";
    close $fh;

    is( $mock->contents, 'hello', '+>> on new file writes correctly' );
};

subtest 'existing >> mode still works' => sub {
    my $mock = Test::MockFile->file( '/tmp/append_existing', 'data' );

    ok( open( my $fh, '>>/tmp/append_existing' ), '>> two-arg still works' ) or diag "open failed: $!";

    print $fh "more";
    close $fh;

    is( $mock->contents, 'datamore', '>> appends correctly' );
};

subtest '+> two-arg still works' => sub {
    my $mock = Test::MockFile->file( '/tmp/trunc_test', 'old' );

    ok( open( my $fh, '+>/tmp/trunc_test' ), '+> two-arg works' ) or diag "open failed: $!";

    # +> truncates
    is( $mock->contents, '', '+> truncates on open' );

    print $fh "new";
    close $fh;

    is( $mock->contents, 'new', '+> write works' );
};

# ============================================================
# Test: opendir follows symlinks
# Bug: __opendir used _get_file_object (no symlink follow)
# ============================================================
subtest 'opendir follows symlink to directory' => sub {
    my $dir    = Test::MockFile->new_dir('/tmp/realdir');
    my $file   = Test::MockFile->file( '/tmp/realdir/child.txt', 'content' );
    my $link   = Test::MockFile->symlink( '/tmp/realdir', '/tmp/dirlink' );

    ok( opendir( my $dh, '/tmp/dirlink' ), 'opendir on symlink to dir succeeds' ) or diag "opendir failed: $!";

    my @entries = sort readdir($dh);
    closedir $dh;

    ok( grep( { $_ eq 'child.txt' } @entries ), 'readdir through symlink finds child file' );
};

subtest 'opendir on broken symlink fails with ENOENT' => sub {
    my $link = Test::MockFile->symlink( '/tmp/nonexistent_dir', '/tmp/broken_dirlink' );

    ok( !opendir( my $dh, '/tmp/broken_dirlink' ), 'opendir on broken symlink fails' );
    is( $! + 0, ENOENT, 'errno is ENOENT for broken symlink' );
};

subtest 'opendir on symlink to file fails with ENOTDIR' => sub {
    my $file = Test::MockFile->file( '/tmp/afile', 'data' );
    my $link = Test::MockFile->symlink( '/tmp/afile', '/tmp/filelink' );

    ok( !opendir( my $dh, '/tmp/filelink' ), 'opendir on symlink to file fails' );
    is( $! + 0, ENOTDIR, 'errno is ENOTDIR' );
};

done_testing();
