#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);
use lib '.';
use t::Util;
use Test::Mock::Net::FTP;

subtest 'normal', sub {
    my $ftp = prepare_ftp();
    $ftp->cwd('dir1');
    $ftp->put( 't/testdata/data1.txt' );
    ok( -e  catfile($ftp->mock_physical_root, 'dir1', 'data1.txt') );
    ok( !-e catfile($ftp->mock_physical_root, 'dir1', 'data2.txt') );

    ok( $ftp->rename('data1.txt', 'data2.txt') );
    ok( !-e catfile($ftp->mock_physical_root, 'dir1', 'data1.txt') );
    ok( -e  catfile($ftp->mock_physical_root, 'dir1', 'data2.txt') );
    done_testing();
};

subtest 'error', sub {
    my $ftp = prepare_ftp();

    ok( !$ftp->rename('no_exist_file.txt', 'data2.txt') );
    isnt( $ftp->message, '');
    done_testing();
};

done_testing();
