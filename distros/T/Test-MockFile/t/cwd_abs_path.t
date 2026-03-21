#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

# Load Cwd AFTER Test::MockFile so imported functions get our override
use Cwd ();
use Cwd qw( abs_path realpath );

# ==========================================================================
# Basic: mocked symlink resolved by Cwd::abs_path (GH #139)
# ==========================================================================

{
    my $mock_link = Test::MockFile->symlink( '/different', '/dest' );

    is( readlink('/dest'), '/different', 'readlink returns mocked target' );
    is( Cwd::abs_path('/dest'), '/different', 'Cwd::abs_path resolves mocked symlink' );
    is( Cwd::realpath('/dest'), '/different', 'Cwd::realpath resolves mocked symlink' );
    is( Cwd::fast_abs_path('/dest'), '/different', 'Cwd::fast_abs_path resolves mocked symlink' );
}

# ==========================================================================
# Non-mocked paths delegate to original Cwd::abs_path
# ==========================================================================

{
    my $cwd = Cwd::getcwd();
    is( Cwd::abs_path('.'), $cwd, 'abs_path(.) returns cwd when nothing is mocked' );
}

# ==========================================================================
# Chained symlinks: a -> b -> c
# ==========================================================================

{
    my $mock_c    = Test::MockFile->file( '/chain_target', 'content' );
    my $mock_b    = Test::MockFile->symlink( '/chain_target', '/chain_mid' );
    my $mock_a    = Test::MockFile->symlink( '/chain_mid', '/chain_start' );

    is( Cwd::abs_path('/chain_start'), '/chain_target', 'abs_path follows chained symlinks' );
}

# ==========================================================================
# Intermediate symlink in path: /link/subdir/file where /link -> /real
# ==========================================================================

{
    my $mock_dir  = Test::MockFile->dir('/real');
    my $mock_link = Test::MockFile->symlink( '/real', '/link' );
    my $mock_file = Test::MockFile->file( '/real/subdir/file.txt', 'data' );

    is( Cwd::abs_path('/link/subdir/file.txt'), '/real/subdir/file.txt',
        'abs_path resolves intermediate symlink in path' );
}

# ==========================================================================
# Relative symlink target
# ==========================================================================

{
    my $mock_target = Test::MockFile->file( '/parent/actual', 'hello' );
    my $mock_link   = Test::MockFile->symlink( 'actual', '/parent/link' );

    is( Cwd::abs_path('/parent/link'), '/parent/actual',
        'abs_path resolves relative symlink target' );
}

# ==========================================================================
# Path with .. component
# ==========================================================================

{
    my $mock_file = Test::MockFile->file( '/a/file.txt', 'data' );

    is( Cwd::abs_path('/a/b/../file.txt'), '/a/file.txt',
        'abs_path resolves .. in path with mocked file' );
}

# ==========================================================================
# Circular symlinks return undef and set ELOOP
# ==========================================================================

{
    my $mock_a = Test::MockFile->symlink( '/circ_b', '/circ_a' );
    my $mock_b = Test::MockFile->symlink( '/circ_a', '/circ_b' );

    local $!;
    my $result = Cwd::abs_path('/circ_a');
    my $err = $! + 0;

    is( $result, undef, 'abs_path returns undef for circular symlinks' );

    use Errno qw/ELOOP/;
    is( $err, ELOOP, '$! is ELOOP for circular symlinks' );
}

# ==========================================================================
# Mocked regular file (not symlink) is resolved correctly
# ==========================================================================

{
    my $mock_file = Test::MockFile->file( '/simple/path', 'content' );

    is( Cwd::abs_path('/simple/path'), '/simple/path',
        'abs_path returns path for mocked regular file' );
}

# ==========================================================================
# abs_path with no argument uses current directory
# ==========================================================================

{
    my $cwd = Cwd::getcwd();
    is( Cwd::abs_path(), $cwd, 'abs_path() with no args returns cwd' );
}

# ==========================================================================
# Symlink to absolute path with deeper nesting
# ==========================================================================

{
    my $mock_link = Test::MockFile->symlink( '/target/deep/path', '/shortcut' );
    my $mock_file = Test::MockFile->file( '/target/deep/path/file', 'data' );

    is( Cwd::abs_path('/shortcut/file'), '/target/deep/path/file',
        'abs_path follows symlink into deeper target path' );
}

# ==========================================================================
# Imported abs_path() also works (not just Cwd::abs_path)
# ==========================================================================

{
    my $mock_link = Test::MockFile->symlink( '/imported_target', '/imported_test' );

    is( abs_path('/imported_test'), '/imported_target',
        'imported abs_path() resolves mocked symlink' );
    is( realpath('/imported_test'), '/imported_target',
        'imported realpath() resolves mocked symlink' );
}

# ==========================================================================
# Symlink target overrides real filesystem (exact scenario from GH #139)
# ==========================================================================

{
    # Even if /dest is a real symlink on disk pointing to /src,
    # when mocked, Cwd::abs_path should see the mocked target.
    my $mock = Test::MockFile->symlink( '/different', '/mock139_dest' );

    is( readlink('/mock139_dest'), '/different', 'GH #139: readlink sees mocked target' );
    is( Cwd::abs_path('/mock139_dest'), '/different', 'GH #139: Cwd::abs_path sees mocked target' );
}

# ==========================================================================
# Relative symlink with .. in target
# ==========================================================================

{
    my $mock_target = Test::MockFile->file( '/base/real_file', 'data' );
    my $mock_link   = Test::MockFile->symlink( '../base/real_file', '/other/link' );

    is( Cwd::abs_path('/other/link'), '/base/real_file',
        'abs_path resolves relative symlink with .. in target' );
}

# ==========================================================================
# Mock goes out of scope — abs_path should fall through to original
# ==========================================================================

{
    {
        my $mock_link = Test::MockFile->symlink( '/mocked_target', '/scoped_link' );
        is( Cwd::abs_path('/scoped_link'), '/mocked_target',
            'abs_path works while mock is in scope' );
    }

    # After mock goes out of scope, /scoped_link is no longer mocked.
    # abs_path should delegate to the original (which may return undef
    # for a non-existent path, depending on the system).
    my $result = Cwd::abs_path('/scoped_link');

    # The path likely doesn't exist on the real filesystem
    ok( !defined $result || $result ne '/mocked_target',
        'abs_path does not return mocked target after mock goes out of scope' );
}

done_testing();
exit 0;
