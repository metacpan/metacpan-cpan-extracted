#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT ENOTEMPTY EISDIR EEXIST ENOTDIR/;
use File::Temp qw/tempfile tempdir/;

my $temp_dir_name = tempdir( CLEANUP => 1 );
CORE::rmdir $temp_dir_name;

use Test::MockFile qw< nostrict >;

# Proves umask works in this test.
umask 022;

subtest "basic rmdir" => sub {
    $! = 0;
    is( CORE::mkdir($temp_dir_name), 1, "REAL mkdir when dir is missing." );
    is( $! + 0,                      0, ' - $! is unset.' ) or diag "$!";
    is( CORE::rmdir $temp_dir_name,  1, "REAL rmdir when dir is there" );

    my $mock = Test::MockFile->dir($temp_dir_name);

    is( mkdir($temp_dir_name), 1,    "MOCK mkdir when dir is missing." );
    is( $! + 0,                0,    ' - $! is unset.' ) or diag "$!";
    is( $mock->permissions,    0755, "Perms are 0755" );
    ok( -d $temp_dir_name, "-d" );

    is( $! + 0,               0, ' - $! is unset.' ) or diag "$!";
    is( rmdir $temp_dir_name, 1, "MOCK rmdir when dir is there" );
    is( $! + 0,               0, ' - $! is unset.' ) or diag "$!";
    ok( !-d $temp_dir_name, "Directory is not there with -d" );
    ok( !-e $temp_dir_name, "Directory is not there with -e" );
};

subtest "undef rmdir" => sub {
    my $returns;

    local $_;
    like( warning { $returns = CORE::rmdir() }, qr/^Use of uninitialized value \$_ in rmdir at.+\n$/, "REAL mkdir when nothing is passed as the directory." );
    is( $returns, 0, " - returns 0" );
    like( warning { $returns = CORE::rmdir(undef) }, qr/^Use of uninitialized value in rmdir at.+\n$/, "REAL mkdir when undef is passed as the directory." );
    is( $returns, 0, " - returns 0" );

    local $_;
    $! = 0;
    like( warning { $returns = rmdir(undef) }, qr/^Use of uninitialized value in rmdir at.+\n$/, "MOCK rmdir when undef is passed as the directory." );
    is( $returns, 0, " - returns 0" );
    is( $! + 0, ENOENT, ' - $! is ENOENT (matches CORE::rmdir behavior)' );
};

subtest "rmdir existing file" => sub {
    CORE::mkdir $temp_dir_name;
    my $temp_file = "$temp_dir_name/a";
    touch($temp_file);

    $! = 0;
    is( rmdir($temp_file), 0,       "real rmdir on existing file." );
    is( $! + 0,            ENOTDIR, ' - $! is ENOTDIR.' ) or diag "$!";
    CORE::unlink $temp_file;

    my $m = Test::MockFile->file( '/abc', '' );

    $! = 0;
    is( rmdir('/abc'), 0,       "mock rmdir on existing file." );
    is( $! + 0,        ENOTDIR, ' - $! is ENOTDIR.' ) or diag "$!";
};

subtest "rmdir existing symlink" => sub {
    CORE::mkdir $temp_dir_name;
    my $temp_file = "$temp_dir_name/a";
    CORE::symlink( "$temp_dir_name/ab", $temp_file );

    $! = 0;
    is( rmdir($temp_file), 0,       "real rmdir on existing file." );
    is( $! + 0,            ENOTDIR, ' - $! is ENOTDIR.' ) or diag "$!";
    CORE::unlink $temp_file;

    my $m = Test::MockFile->symlink( '/someotherpath', '/abc' );

    $! = 0;
    is( rmdir('/abc'), 0,       "mock rmdir on existing file." );
    is( $! + 0,        ENOTDIR, ' - $! is ENOTDIR.' ) or diag "$!";
};

subtest "rmdir when nothing is there." => sub {
    CORE::mkdir $temp_dir_name;
    my $temp_dir = "$temp_dir_name/a";

    $! = 0;
    is( rmdir($temp_dir), 0,      "real rmdir on existing file." );
    is( $! + 0,           ENOENT, ' - $! is ENOENT.' ) or diag "$!";

    my $m = Test::MockFile->dir('/abc');

    $! = 0;
    is( rmdir('/abc'), 0,      "mock rmdir on existing file." );
    is( $! + 0,        ENOENT, ' - $! is ENOENT.' ) or diag "$!";
};

subtest(
    'rmdir non-empty directory fails' => sub {
        my $foo = Test::MockFile->dir('/foo');
        my $bar = Test::MockFile->file( '/foo/bar', 'content' );

        $! = 0;

        ok( -e ('/foo/bar'), 'File exists' );
        ok( -d ('/foo'),     'Directory exists' );

        is( $! + 0, 0, 'No errors yet' );
        ok( !rmdir('/foo'), 'rmdir failed because directory has files' );
        is( $! + 0, ENOTEMPTY, '$! is ENOTEMPTY' );
    }
);

subtest(
    'rmdir succeeds when only non-existent mocks exist in directory' => sub {
        my $dir  = Test::MockFile->new_dir('/mydir');
        my $file = Test::MockFile->file('/mydir/ghost');    # non-existent placeholder (undef contents)

        ok( -d '/mydir',   'Directory exists' );
        ok( !-e '/mydir/ghost', 'Ghost file does not exist' );

        $! = 0;
        is( rmdir('/mydir'), 1, 'rmdir succeeds on dir with only non-existent child mocks' );
        is( $! + 0,          0, '$! is not set' ) or diag "$!";
        ok( !-d '/mydir', 'Directory no longer exists after rmdir' );
    }
);

subtest(
    'rmdir fails when at least one existing file is in directory' => sub {
        my $dir   = Test::MockFile->new_dir('/mixdir');
        my $ghost = Test::MockFile->file('/mixdir/ghost');              # non-existent
        my $real  = Test::MockFile->file( '/mixdir/real', 'content' ); # exists

        ok( -d '/mixdir',       'Directory exists' );
        ok( !-e '/mixdir/ghost', 'Ghost file does not exist' );
        ok( -e '/mixdir/real',  'Real file exists' );

        $! = 0;
        ok( !rmdir('/mixdir'), 'rmdir fails when existing file is present' );
        ok( $! + 0, '$! is set' );
        ok( -d '/mixdir', 'Directory still exists' );
    }
);

done_testing();

sub touch {
    my $path = shift or die;

    CORE::open( my $fh, '>>', $path ) or die;
    print $fh '';
    close $fh;

    return 1;
}
