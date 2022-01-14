#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EISDIR/;
use File::Temp qw/tempfile tempdir/;

my $temp_dir_name = tempdir( CLEANUP => 1 );

my ( undef, $missing_file_name ) = tempfile();
CORE::unlink($missing_file_name);

my ( $fh, $existing_file_name ) = tempfile();
print $fh "This is the real file\n";
close $fh;

use Test::MockFile ();

subtest 'unlink on a missing file' => sub {
    $! = 0;
    is( CORE::unlink($missing_file_name), 0,      "REAL CORE::unlink returns 0 files deleted." );
    is( $! + 0,                           ENOENT, '$! is set to ENOENT' );

    my $mock = Test::MockFile->file($missing_file_name);

    $! = 0;
    is( unlink($missing_file_name), 0,      "MOCKED unlink returns 0 files deleted." );
    is( $! + 0,                     ENOENT, '$! is set to ENOENT' );
};

subtest 'unlink on an existing directory' => sub {
    $! = 0;
    is( CORE::unlink($temp_dir_name), 0, "REAL CORE::unlink returns 0 files deleted." );
    my $real_dir_unlink_error = $! + 0;

    my $mock = Test::MockFile->dir($temp_dir_name);
    ok( !-d $temp_dir_name,    'Directory does not exist yet' );
    ok( mkdir($temp_dir_name), 'Created directory successfully' );
    ok( -d $temp_dir_name,     'Directory now exists' );

    $! = 0;
    is( unlink($temp_dir_name), 0, "MOCKED unlink returns 0 files deleted." );
  SKIP: {
        skip q{This docker container doesn't emit $! failures reliably.}, 1 if on_broken_docker();
        is( $! + 0, $real_dir_unlink_error, '$! is set to EISDIR' );
    }
};

subtest 'unlink on an existing file' => sub {
    $! = 0;
    is( CORE::unlink($existing_file_name), 1, "REAL CORE::unlink returns 1 files deleted." );
    is( $! + 0,                            0, '$! remains 0' );

    my $mock = Test::MockFile->file( $existing_file_name, "abc" );

    $! = 0;
    is( unlink($existing_file_name), 1, "MOCKED unlink returns 1 files deleted." );
    is( $! + 0,                      0, '$! remains 0' );
};

subtest 'unlink on an unmocked file' => sub {

    CORE::open( $fh, '>', $existing_file_name ) or die;
    print $fh "This is the real file\n";
    close $fh;

    $! = 0;
    is( unlink($existing_file_name), 1, "MOCKED unlink returns 1 files deleted." );
    is( $! + 0,                      0, '$! remains 0' );

    is( CORE::open( $fh, '<', $existing_file_name ), undef,  "CORE::open fails since the file is removed from disk" );
    is( $! + 0,                                      ENOENT, '$! becomes ENOENT' );

};

done_testing();

sub on_broken_docker {
    return 0 if $] > 5.019;
    return 0 unless -f '/.dockerenv';
    return 1;
}
