#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);
use FindBin;
use lib $FindBin::Bin;
use t::Util;
use Test::Mock::Net::FTP qw(intercept);


use Net::FTP;

subtest 'intercept', sub {
    my $ftp = Net::FTP->new('somehost.example.com');# (replaced by Test::Mock::Net::FTP)
    ok( defined $ftp );

    $ftp->login('user1', 'secret');
    $ftp->cwd('dir1');
    $ftp->put( catfile('t', 'testdata', 'data1.txt') );
    file_contents_ok( catfile('tmp', 'ftpserver', 'dir1', 'data1.txt'), "this is testdata #1\n" );

    $ftp->close();
    done_testing();
};

done_testing();
