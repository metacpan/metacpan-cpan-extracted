#!/usr/bin/perl

use strict;
use warnings;

use File::Path qw(remove_tree make_path);
use File::Copy;
use File::Spec::Functions qw(catfile catdir);
use Test::More;
use lib '.';
use t::Util;
use Test::Mock::Net::FTP;


copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp', 'ftpserver', 'dir2', 'data1.txt' ) );
copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp', 'ftpserver', 'dir2', 'data2.txt' ) );

subtest 'specify directory', sub {
    my $ftp = prepare_ftp();

    my @dir_result = $ftp->dir('dir2');
    is( scalar(@dir_result), 3 );
    like( $dir_result[0], qr/^total\s+\d+$/ );
    like( $dir_result[1], qr/data1\.txt$/ );

    my $dir_result_aref = $ftp->dir('dir2'); #scalar context
    is( ref $dir_result_aref, 'ARRAY' );
    is( scalar(@{ $dir_result_aref }), 3 );
    like( $dir_result_aref->[1], qr/data1\.txt$/);
    done_testing();
};

subtest 'dir to current directory', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir2');
    my @dir_result = $ftp->dir();
    is( scalar(@dir_result), 3 );
    like( $dir_result[0], qr/^total\s+\d+$/ );
    like( $dir_result[1], qr/data1\.txt$/ );

    done_testing();
};

subtest 'specify absolute path', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd();
    my @dir_result = $ftp->dir('/ftproot/dir2'); #absolute path
    is( scalar(@dir_result), 3 );
    like( $dir_result[0], qr/^total\s+\d+$/ );
    like( $dir_result[1], qr/data1\.txt$/ );

    done_testing();
};


done_testing();
