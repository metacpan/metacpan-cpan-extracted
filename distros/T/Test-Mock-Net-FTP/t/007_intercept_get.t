#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

use File::Path qw(remove_tree make_path);
use File::Copy;
use File::Spec::Functions qw(catfile catdir);
use Cwd qw(chdir getcwd);
use FindBin;
use lib $FindBin::Bin;
use t::Util;
use Test::Mock::Net::FTP qw(intercept);
use Net::FTP;
use Cwd;

copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp', 'ftpserver', 'dir1', 'data1.txt' ) );

subtest 'intercept get', sub {
    my $ftp = Net::FTP->new('somehost.example.com'); #replaced by Test::Mock::Net::FTP
    $ftp->login('user1', 'secret');

    my $cwd = getcwd();
    chdir 'tmp';

    $ftp->cwd('dir1');
    $ftp->get( 'data1.txt' );
    file_contents_ok('data1.txt', "this is testdata #1\n");

    chdir $cwd;
    done_testing();
};

done_testing();
