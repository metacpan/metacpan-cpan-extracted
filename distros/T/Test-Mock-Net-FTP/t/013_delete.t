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
    ok( -e catfile($ftp->mock_physical_root, 'dir1', 'data1.txt') );

    ok( $ftp->delete('data1.txt') );
    ok( !-e catfile($ftp->mock_physical_root, 'dir1', 'data1.txt') );

    done_testing();
};

subtest 'error', sub {
    my $ftp = prepare_ftp();

    ok( !$ftp->delete('no_exist_file.txt') );
    isnt( $ftp->message, '');

    done_testing();
};


done_testing();
