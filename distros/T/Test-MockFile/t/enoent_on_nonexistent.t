#!/usr/bin/perl -w

# Regression test for Overload::FileCheck GH#13
# When a file is mocked as non-existent (undef contents),
# -e should set $! to ENOENT, not EBADF.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EBADF ELOOP/;

use Test::MockFile;

subtest '-e on non-existent mock sets ENOENT' => sub {
    my $path = '/some/nonexistent/path';
    my $mock = Test::MockFile->file( $path, undef );

    $! = 0;
    my $exists = -e $path;

    ok( !$exists, '-e returns false for file mocked with undef contents' );
    is( $! + 0, ENOENT, '$! is ENOENT (not EBADF) after -e on non-existent mock' );
};

subtest '-e on non-existent mock (no content arg)' => sub {
    my $path = '/another/missing/file';
    my $mock = Test::MockFile->file($path);

    $! = 0;
    my $exists = -e $path;

    ok( !$exists, '-e returns false for file mocked without content' );
    is( $! + 0, ENOENT, '$! is ENOENT after -e on file mocked without content' );
};

subtest '-f on non-existent mock sets ENOENT' => sub {
    my $path = '/mock/not/a/file';
    my $mock = Test::MockFile->file( $path, undef );

    $! = 0;
    my $is_file = -f $path;

    ok( !$is_file, '-f returns false for file mocked with undef contents' );
    is( $! + 0, ENOENT, '$! is ENOENT after -f on non-existent mock' );
};

subtest '-d on non-existent mock sets ENOENT' => sub {
    my $path = '/mock/not/a/dir';
    my $mock = Test::MockFile->dir($path);

    $! = 0;
    my $is_dir = -d $path;

    ok( !$is_dir, '-d returns false for non-existent dir mock' );
    is( $! + 0, ENOENT, '$! is ENOENT after -d on non-existent dir mock' );
};

subtest 'stat on non-existent mock fails cleanly' => sub {
    my $path = '/mock/no/stat';
    my $mock = Test::MockFile->file( $path, undef );

    $! = 0;
    my @st = stat($path);

    is( scalar @st, 0, 'stat returns empty list for non-existent mock' );

    # errno after stat() on non-existent mock depends on Overload::FileCheck's XS
    # cleanup behavior. The _check() Perl code sets ENOENT correctly, but the XS
    # FREETMPS/LEAVE in _overload_ft_stat() may clobber errno before returning.
    # File checks (-e, -f, etc.) are unaffected because _check_from_stat checks
    # array length rather than errno. See cpanel/Overload-FileCheck for the fix.
    todo 'Overload::FileCheck XS clobbers errno on stat failure path' => sub {
        is( $! + 0, ENOENT, '$! is ENOENT after stat on non-existent mock' );
    };
};

subtest 'lstat on non-existent mock fails cleanly' => sub {
    my $path = '/mock/no/lstat';
    my $mock = Test::MockFile->file( $path, undef );

    $! = 0;
    my @st = lstat($path);

    is( scalar @st, 0, 'lstat returns empty list for non-existent mock' );

    todo 'Overload::FileCheck XS clobbers errno on stat failure path' => sub {
        is( $! + 0, ENOENT, '$! is ENOENT after lstat on non-existent mock' );
    };
};

subtest '-e succeeds for existing mock' => sub {
    my $path = '/mock/exists';
    my $mock = Test::MockFile->file( $path, 'content' );

    $! = 0;
    my $exists = -e $path;

    ok( $exists, '-e returns true for file mocked with content' );
    is( $! + 0, 0, '$! is not set after successful -e' );
};

subtest '-e on broken symlink sets ENOENT (not ELOOP)' => sub {
    # Symlink to a target with no mock = broken symlink
    my $link = Test::MockFile->symlink( '/nonexistent_target', '/broken_stat_link' );

    $! = 0;
    my $exists = -e '/broken_stat_link';

    ok( !$exists, '-e returns false for broken symlink' );
    is( $! + 0, ENOENT, '$! is ENOENT (not ELOOP) for broken symlink' );
};

subtest 'stat on broken symlink sets ENOENT' => sub {
    my $link = Test::MockFile->symlink( '/no_such_target', '/broken_stat_link2' );

    $! = 0;
    my @st = stat('/broken_stat_link2');

    is( scalar @st, 0, 'stat returns empty list for broken symlink' );
    todo 'Overload::FileCheck XS clobbers errno on stat failure path' => sub {
        is( $! + 0, ENOENT, '$! is ENOENT after stat on broken symlink' );
    };
};

subtest '-e on circular symlink sets ELOOP' => sub {
    # Two symlinks pointing at each other = circular
    my $a = Test::MockFile->symlink( '/circ_b', '/circ_a' );
    my $b = Test::MockFile->symlink( '/circ_a', '/circ_b' );

    $! = 0;
    my $exists = -e '/circ_a';

    ok( !$exists, '-e returns false for circular symlink' );
    is( $! + 0, ELOOP, '$! is ELOOP for circular symlink' );
};

subtest 'lstat on broken symlink succeeds (reports the link itself)' => sub {
    my $link = Test::MockFile->symlink( '/nowhere', '/broken_lstat_link' );

    $! = 0;
    my @st = lstat('/broken_lstat_link');

    ok( scalar @st > 0, 'lstat returns stats for broken symlink (the link itself)' );
    is( $! + 0, 0, '$! is not set after successful lstat on broken symlink' );
};

done_testing();
