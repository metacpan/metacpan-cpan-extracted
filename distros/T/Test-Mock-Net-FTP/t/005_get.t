#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use File::Copy;
use File::Spec::Functions qw(catfile);
use lib '.';
use t::Util;
use Test::Mock::Net::FTP;
use Cwd;

copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp/ftpserver', 'dir1', 'data1.txt' ) );

subtest 'get', sub {
    my $ftp = prepare_ftp();
    my $cwd = getcwd();
    chdir 'tmp';

    $ftp->cwd('dir1');
    is( $ftp->get( 'data1.txt' ), 'data1.txt' );
    file_contents_ok('data1.txt', "this is testdata #1\n");
    unlink( 'data1.txt' );

    chdir $cwd;
    done_testing();
};

subtest 'specify canonical path', sub {
    my $ftp = prepare_ftp();
    my $cwd = getcwd();
    chdir 'tmp';

    $ftp->get( 'dir1/data1.txt' );
    file_contents_ok('data1.txt', "this is testdata #1\n");
    unlink( 'data1.txt' );

    chdir $cwd;
    done_testing();
};

subtest 'absolute path and local filename', sub {
    my $ftp = prepare_ftp();
    my $cwd = getcwd();
    chdir 'tmp';

    $ftp->cwd();
    $ftp->get( '/ftproot/dir1/data1.txt', 'data1_copy.txt' );
    file_contents_ok('data1_copy.txt', "this is testdata #1\n");
    unlink( 'data1_copy.txt' );

    chdir $cwd;
    done_testing();
};

subtest 'error', sub {
    my $ftp = prepare_ftp();
    my $cwd = getcwd();
    chdir 'tmp';

    $ftp->cwd();
    is( $ftp->get('no_exist.txt'), undef );
    isnt( $ftp->message, '');

    chdir $cwd;
    done_testing();
};



done_testing();
