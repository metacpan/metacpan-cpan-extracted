#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EISDIR ELOOP/;

use Test::MockFile qw< nostrict >;

# ===================================================================
# open() failure paths must return undef (not empty list).
#
# Bare "return;" returns () in list context, which gives scalar(@ret)=0.
# Correct behavior: "return undef;" returns (undef) — scalar(@ret)=1.
# This matches CORE::open which returns undef on failure.
# ===================================================================

subtest 'open on non-existent file returns undef in scalar and list context' => sub {
    my $mock = Test::MockFile->file('/fake/noexist');

    # Scalar context
    my $ret = open( my $fh, '<', '/fake/noexist' );
    is( $ret, undef, 'open returns undef in scalar context for non-existent file' );
    is( $! + 0, ENOENT, 'errno is ENOENT' );

    # List context — should return (undef), not ()
    my @ret = open( my $fh2, '<', '/fake/noexist' );
    is( scalar @ret, 1, 'open returns 1-element list in list context (not empty)' );
    is( $ret[0], undef, 'the single element is undef' );
};

subtest 'open on directory returns undef (EISDIR)' => sub {
    my $mock_dir = Test::MockFile->dir('/fake/mydir');

    # Scalar context
    my $ret = open( my $fh, '>', '/fake/mydir' );
    is( $ret, undef, 'open on directory returns undef in scalar context' );
    is( $! + 0, EISDIR, 'errno is EISDIR' );

    # List context
    my @ret = open( my $fh2, '>', '/fake/mydir' );
    is( scalar @ret, 1, 'open on directory returns 1-element list in list context' );
    is( $ret[0], undef, 'the single element is undef' );
};

subtest 'open on broken symlink returns undef (ENOENT)' => sub {
    my $mock_link = Test::MockFile->symlink( '/fake/nonexistent_target', '/fake/broken_link' );

    # Scalar context
    my $ret = open( my $fh, '<', '/fake/broken_link' );
    is( $ret, undef, 'open on broken symlink returns undef in scalar context' );
    is( $! + 0, ENOENT, 'errno is ENOENT for broken symlink' );

    # List context
    my @ret = open( my $fh2, '<', '/fake/broken_link' );
    is( scalar @ret, 1, 'open on broken symlink returns 1-element list in list context' );
    is( $ret[0], undef, 'the single element is undef' );
};

subtest 'open on circular symlink returns undef (ELOOP)' => sub {
    my $mock_a = Test::MockFile->symlink( '/fake/link_b', '/fake/link_a' );
    my $mock_b = Test::MockFile->symlink( '/fake/link_a', '/fake/link_b' );

    # Scalar context
    my $ret = open( my $fh, '<', '/fake/link_a' );
    is( $ret, undef, 'open on circular symlink returns undef in scalar context' );
    is( $! + 0, ELOOP, 'errno is ELOOP for circular symlink' );

    # List context
    my @ret = open( my $fh2, '<', '/fake/link_a' );
    is( scalar @ret, 1, 'open on circular symlink returns 1-element list in list context' );
    is( $ret[0], undef, 'the single element is undef' );
};

done_testing();
