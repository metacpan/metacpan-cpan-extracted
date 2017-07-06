#!/usr/bin/perl -w

use strict;
use warnings;

use File::Copy;
use File::Spec::Functions qw(catfile);

use Test::More;
use FindBin;
use lib $FindBin::Bin;
use t::Util;
use Test::Mock::Net::FTP;

copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp', 'ftpserver', 'dir2', 'data1.txt' ) );
copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp', 'ftpserver', 'dir2', 'data2.txt' ) );

subtest 'ls to dir', sub {
    my $ftp = prepare_ftp();

    my @ls_result = $ftp->ls('dir2');
    is( scalar(@ls_result), 2 );
    is( $ls_result[0], 'dir2/data1.txt' );

    my $ls_result_aref = $ftp->ls('dir2'); #scalar context
    is( ref $ls_result_aref, 'ARRAY' );
    is( scalar(@{ $ls_result_aref }), 2);
    is( $ls_result_aref->[0], 'dir2/data1.txt');
    done_testing();
};

subtest 'ls to current dir', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir2');
    my @ls_result = $ftp->ls();
    is( scalar(@ls_result), 2 );
    is( $ls_result[0], 'data1.txt' );

    done_testing();
};

subtest 'specify absolute path', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd();
    my @ls_result = $ftp->ls('/ftproot/dir2'); #absolute path
    is( scalar(@ls_result), 2 );
    is( $ls_result[0], '/ftproot/dir2/data1.txt' );

    done_testing();
};


done_testing();
