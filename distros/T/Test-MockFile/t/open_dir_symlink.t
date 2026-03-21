#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl;
use Errno qw/EISDIR ENOENT ELOOP/;

use Test::MockFile qw< nostrict >;

# =======================================================
# EISDIR: open() on a directory mock should fail
# =======================================================

note "--- open() on directory mocks returns EISDIR ---";

{
    my $dir = Test::MockFile->new_dir('/fake/dir');

    ok( -d '/fake/dir', "Directory mock exists" );

    ok( !open( my $fh, '<', '/fake/dir' ), "open('<') on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for read open on dir" );

    ok( !open( $fh, '>', '/fake/dir' ), "open('>') on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for write open on dir" );

    ok( !open( $fh, '>>', '/fake/dir' ), "open('>>') on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for append open on dir" );

    ok( !open( $fh, '+<', '/fake/dir' ), "open('+<') on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for read-write open on dir" );

    ok( !open( $fh, '+>', '/fake/dir' ), "open('+>') on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for write-read open on dir" );
}

# =======================================================
# EISDIR: sysopen() on a directory mock should fail
# =======================================================

note "--- sysopen() on directory mocks returns EISDIR ---";

{
    my $dir = Test::MockFile->new_dir('/fake/sysdir');

    ok( -d '/fake/sysdir', "Directory mock exists" );

    ok( !sysopen( my $fh, '/fake/sysdir', O_RDONLY ), "sysopen(O_RDONLY) on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for O_RDONLY sysopen on dir" );

    ok( !sysopen( $fh, '/fake/sysdir', O_WRONLY ), "sysopen(O_WRONLY) on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for O_WRONLY sysopen on dir" );

    ok( !sysopen( $fh, '/fake/sysdir', O_RDWR ), "sysopen(O_RDWR) on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR for O_RDWR sysopen on dir" );

    ok( !sysopen( $fh, '/fake/sysdir', O_WRONLY | O_CREAT ), "sysopen(O_WRONLY|O_CREAT) on dir fails" );
    is( $! + 0, EISDIR, "errno is EISDIR even with O_CREAT on dir" );
}

# =======================================================
# sysopen() follows symlinks to the target file
# =======================================================

note "--- sysopen() follows symlinks ---";

{
    my $file    = Test::MockFile->file( '/fake/target', 'original' );
    my $symlink = Test::MockFile->symlink( '/fake/target', '/fake/link' );

    ok( -l '/fake/link',   "Symlink mock exists" );
    ok( -f '/fake/target', "Target file exists" );

    # sysopen through symlink for reading
    ok( sysopen( my $fh, '/fake/link', O_RDONLY ), "sysopen(O_RDONLY) through symlink succeeds" );
    my $buf;
    sysread( $fh, $buf, 100 );
    is( $buf, 'original', "Read through symlink returns target contents" );
    close $fh;

    # sysopen through symlink for writing
    ok( sysopen( $fh, '/fake/link', O_WRONLY | O_TRUNC ), "sysopen(O_WRONLY|O_TRUNC) through symlink succeeds" );
    syswrite( $fh, 'updated' );
    close $fh;
    is( $file->contents(), 'updated', "Write through symlink updates target file" );
}

# =======================================================
# sysopen() with O_NOFOLLOW rejects symlinks with ELOOP
# =======================================================

note "--- sysopen() O_NOFOLLOW rejects symlinks ---";

{
    my $file    = Test::MockFile->file( '/fake/target2', 'data' );
    my $symlink = Test::MockFile->symlink( '/fake/target2', '/fake/link2' );

    ok( !sysopen( my $fh, '/fake/link2', O_RDONLY | O_NOFOLLOW ), "sysopen(O_NOFOLLOW) on symlink fails" );
    is( $! + 0, ELOOP, "errno is ELOOP for O_NOFOLLOW on symlink" );

    # O_NOFOLLOW on a regular file should work fine
    ok( sysopen( $fh, '/fake/target2', O_RDONLY | O_NOFOLLOW ), "sysopen(O_NOFOLLOW) on regular file succeeds" );
    close $fh;
}

# =======================================================
# sysopen() through a broken symlink returns ENOENT
# =======================================================

note "--- sysopen() through broken symlink returns ENOENT ---";

{
    # A symlink pointing to a path with no mock at all
    my $symlink = Test::MockFile->symlink( '/fake/nowhere', '/fake/broken_link' );

    ok( -l '/fake/broken_link', "Broken symlink mock exists" );

    ok( !sysopen( my $fh, '/fake/broken_link', O_RDONLY ), "sysopen(O_RDONLY) through broken symlink fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for broken symlink" );

    ok( !sysopen( $fh, '/fake/broken_link', O_WRONLY ), "sysopen(O_WRONLY) through broken symlink fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for broken symlink write" );
}

# =======================================================
# sysopen() through a circular symlink returns ELOOP
# =======================================================

note "--- sysopen() through circular symlink returns ELOOP ---";

{
    my $link_a = Test::MockFile->symlink( '/fake/circ_b', '/fake/circ_a' );
    my $link_b = Test::MockFile->symlink( '/fake/circ_a', '/fake/circ_b' );

    ok( !sysopen( my $fh, '/fake/circ_a', O_RDONLY ), "sysopen through circular symlink fails" );
    is( $! + 0, ELOOP, "errno is ELOOP for circular symlink" );
}

# =======================================================
# Double O_TRUNC was removed: verify O_TRUNC works correctly once
# =======================================================

note "--- sysopen() O_TRUNC applied correctly ---";

{
    my $file = Test::MockFile->file( '/fake/trunc', 'existing content' );

    ok( sysopen( my $fh, '/fake/trunc', O_WRONLY | O_TRUNC ), "sysopen(O_WRONLY|O_TRUNC) succeeds" );
    is( $file->contents(), '', "O_TRUNC clears file contents" );
    syswrite( $fh, 'new' );
    close $fh;
    is( $file->contents(), 'new', "Contents after O_TRUNC write" );
}

{
    # O_TRUNC without O_CREAT on non-existent file should fail
    my $file = Test::MockFile->file('/fake/trunc_noexist');

    ok( !sysopen( my $fh, '/fake/trunc_noexist', O_RDONLY | O_TRUNC ), "sysopen(O_RDONLY|O_TRUNC) on non-existent fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for O_TRUNC on non-existent" );
    ok( !defined $file->contents(), "Contents still undef (file not created)" );
}

# =======================================================
# Verify directory mock state is not corrupted
# =======================================================

note "--- directory mock state preserved after failed open ---";

{
    my $dir = Test::MockFile->new_dir('/fake/preserved_dir');

    # Attempt to open it (should fail)
    open( my $fh, '>', '/fake/preserved_dir' );

    # Verify the mock is still a healthy directory
    ok( -d '/fake/preserved_dir', "Dir is still a directory after failed open" );
    is( ref $dir->contents(), 'ARRAY', "Dir contents still returns arrayref" );
}

done_testing();
