#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT EINVAL/;
use File::Temp qw/tempfile tempdir/;

my $temp_dir_name = tempdir( CLEANUP => 1 );

my $file = "$temp_dir_name/a";
open( my $fh, ">", $file ) or die;
print $fh "abc\n";
close $fh;

my $symlink     = "$temp_dir_name/b";
my $bad_symlink = "$temp_dir_name/c";
CORE::symlink( "a",        $symlink );
CORE::symlink( "notafile", $bad_symlink );

use Test::MockFile qw< nostrict >;

note "-------------- REAL MODE --------------";
$! = 0;
is( CORE::readlink("$temp_dir_name/missing_file"), undef,  "readlink on missing file " );
is( $! + 0,                                        ENOENT, '$! is ENOENT for a missing file readlink.' );

$! = 0;
is( CORE::readlink($symlink), 'a', "readlink on a working symlink works." );
is( $! + 0,                   0,   '$! is 0 for a missing file readlink.' );

$! = 0;
is( CORE::readlink($bad_symlink), 'notafile', "readlink on a broken symlink still works." );
is( $! + 0,                       0,          '$! is 0 for a missing file readlink.' );

$! = 0;
is( CORE::readlink($file), undef,  "readlink on a file is undef." );
is( $! + 0,                EINVAL, '$! is EINVAL for a readlink on a file.' );

$! = 0;
is( CORE::readlink($temp_dir_name), undef,  "readlink on a dir is undef." );
is( $! + 0,                         EINVAL, '$! is EINVAL for a readlink on a dir.' );

$! = 0;
my $got = 'abc';
like( warning { $got = CORE::readlink(undef) }, qr/^Use of uninitialized value in readlink at /, "Got expected warning for passing no value to readlink" );
is( $got, undef, "readlink without args is undef." );
if ( $^O eq 'freebsd' ) {
    is( $! + 0, EINVAL, '$! is EINVAL for a readlink(undef)' );
}
else {
    is( $! + 0, ENOENT, '$! is ENOENT for a readlink(undef)' );
}

$!   = 0;
$got = 'abc';
like( warning { $got = CORE::readlink() }, qr/^Use of uninitialized value \$_ in readlink at /, "Got expected warning for passing no value to readlink" );
is( $got, undef, "readlink without args is undef." );
if ( $^O eq 'freebsd' ) {
    is( $! + 0, EINVAL, '$! is EINVAL for a readlink(undef)' );
}
else {
    is( $! + 0, ENOENT, '$! is ENOENT for a readlink(undef)' );
}

note "Cleaning up...";
CORE::unlink( $symlink, $bad_symlink, $file );

note "-------------- MOCK MODE --------------";
$temp_dir_name = '/a/random/path/not/on/disk';
$file          = "$temp_dir_name/a";
$symlink       = "$temp_dir_name/b";
$bad_symlink   = "$temp_dir_name/c";

my @mocks;
push @mocks, Test::MockFile->file($file);
push @mocks, Test::MockFile->dir($temp_dir_name);
push @mocks, Test::MockFile->symlink( "a",        $symlink );
push @mocks, Test::MockFile->symlink( "notafile", $bad_symlink );

$! = 0;
is( readlink("$temp_dir_name/missing_file"), undef,  "readlink on missing file " );
is( $! + 0,                                  ENOENT, '$! is ENOENT for a missing file readlink.' );

$! = 0;
is( readlink($symlink), 'a', "readlink on a working symlink works." );
is( $! + 0,             0,   '$! is 0 for a missing file readlink.' );

$! = 0;
is( readlink($bad_symlink), 'notafile', "readlink on a broken symlink still works." );
is( $! + 0,                 0,          '$! is 0 for a missing file readlink.' );

$! = 0;
is( readlink($file), undef,  "readlink on a file is undef." );
is( $! + 0,          EINVAL, '$! is EINVAL for a readlink on a file.' );

$! = 0;
is( readlink($temp_dir_name), undef,  "readlink on a dir is undef." );
is( $! + 0,                   EINVAL, '$! is EINVAL for a readlink on a dir.' );

$!   = 0;
$got = 'abc';
like( warning { $got = readlink(undef) }, qr/^Use of uninitialized value in readlink at /, "Got expected warning for passing no value to readlink" );
is( $got, undef, "readlink without args is undef." );
if ( $^O eq 'freebsd' ) {
    is( $! + 0, EINVAL, '$! is EINVAL for a readlink(undef)' );
}
else {
    is( $! + 0, ENOENT, '$! is ENOENT for a readlink(undef)' );
}

$!   = 0;
$got = 'abc';
todo "Something's wrong with readlink's prototype and the warning is incorrect no matter what we do in the code." => sub {
    like( warning { $got = readlink() }, qr/^Use of uninitialized value \$_ in readlink at /, "Got expected warning for passing no value to readlink" );
};
is( $got, undef, "readlink without args is undef." );
if ( $^O eq 'freebsd' ) {
    is( $! + 0, EINVAL, '$! is EINVAL for a readlink(undef)' );
}
else {
    is( $! + 0, ENOENT, '$! is ENOENT for a readlink(undef)' );
}

done_testing();
