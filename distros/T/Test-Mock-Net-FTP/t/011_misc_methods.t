#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use lib '.';
use t::Util;
use Test::Mock::Net::FTP;
use File::Spec::Functions qw(catfile);
use File::Copy;

subtest 'transfer mode', sub {
    my $ftp = prepare_ftp();
    is( $ftp->mock_transfer_mode(), 'ascii');#default transfer mode is ascii

    $ftp->binary();
    is( $ftp->mock_transfer_mode(), 'binary');

    $ftp->ascii();
    is( $ftp->mock_transfer_mode(), 'ascii');

    done_testing();
};

subtest 'connection mode', sub {
    my $ftp = prepare_ftp();
    is( $ftp->mock_connection_mode(), 'pasv');
    is( $ftp->mock_port_no(),         '');

    $ftp->port(1234);
    is( $ftp->mock_connection_mode(), 'port');
    is( $ftp->mock_port_no(),         '1234');

    $ftp->pasv();
    is( $ftp->mock_connection_mode(), 'pasv');
    is( $ftp->mock_port_no(),         '');

    # specify port mode(and default port no)
    $ftp = prepare_ftp(Passive=>0);
    is( $ftp->mock_connection_mode(), 'port');
    is( $ftp->mock_port_no(),         '20');

    # specify port no
    $ftp = prepare_ftp(Port=>1122);
    is( $ftp->mock_connection_mode(), 'port');
    is( $ftp->mock_port_no(),         '1122');

    done_testing();
};

subtest 'site', sub {
    my $ftp = prepare_ftp();
    $ftp->site("help");
    ok(1); #dummy
    done_testing();
};

subtest 'hash', sub {
    my $ftp = prepare_ftp();
    $ftp->hash();
    ok(1); #dummy
    done_testing();
};

subtest 'alloc', sub {
    my $ftp = prepare_ftp();
    $ftp->alloc(1024);
    ok(1); #dummy
    done_testing();
};

subtest 'nlst', sub {
    my $ftp = prepare_ftp();
    $ftp->nlst('aaa');
    ok(1); #dummy
    done_testing();
};

subtest 'list', sub {
    my $ftp = prepare_ftp();
    $ftp->list('aaa');
    ok(1); #dummy
    done_testing();
};

subtest 'retr', sub {
    my $ftp = prepare_ftp();
    $ftp->retr('file.txt');
    ok(1); #dummy
    done_testing();
};

subtest 'stor', sub {
    my $ftp = prepare_ftp();
    $ftp->stor('file.txt');
    ok(1); #dummy
    done_testing();
};

subtest 'stou', sub {
    my $ftp = prepare_ftp();
    $ftp->stou('file.txt');
    ok(1); #dummy
    done_testing();
};

subtest 'appe', sub {
    my $ftp = prepare_ftp();
    $ftp->appe('file.txt');
    ok(1); #dummy
    done_testing();
};

subtest 'quot', sub {
    my $ftp = prepare_ftp();
    $ftp->quot('somecmd');
    ok(1); #dummy
    done_testing();
};

subtest 'supported', sub {
    my $ftp = prepare_ftp();
    ok( $ftp->supported() );
    done_testing();
};

subtest 'authorize', sub {
    my $ftp = prepare_ftp();
    $ftp->authorize();
    ok(1); #dummy
    done_testing();
};

subtest 'feature', sub {
    my $ftp = prepare_ftp();
    is_deeply([$ftp->feature('MDTM')], ['MDTM']);
    done_testing();
};

subtest 'restart', sub {
    my $ftp = prepare_ftp();
    $ftp->restart('somewhere');
    ok(1); #dummy
    done_testing();
};

subtest 'pasv_xfer', sub {
    my $ftp = prepare_ftp();
    $ftp->pasv_xfer('file.txt', 'someserver');
    ok(1); #dummy
    done_testing();
};

subtest 'pasv_xfer_unique', sub {
    my $ftp = prepare_ftp();
    $ftp->pasv_xfer_unique('file.txt', 'someserver');
    ok(1); #dummy
    done_testing();
};

subtest 'pasv_wait', sub {
    my $ftp = prepare_ftp();
    $ftp->pasv_wait('someserver');
    ok(1); #dummy
    done_testing();
};


subtest 'size', sub {
    my $ftp = prepare_ftp();
    copy( catfile('t', 'testdata', 'data1.txt'), catfile('tmp', 'ftpserver', 'dir1', 'data1.txt' ) );
    $ftp->cwd('dir1');
    is( $ftp->size("data1.txt"), 20 );
    unlink catfile('tmp', 'ftpserver', 'dir1', 'data1.txt' );
    done_testing();
};

subtest 'mdtm', sub {
    my $ftp = prepare_ftp();
    my $dest = catfile('tmp', 'ftpserver', 'dir1', 'data1.txt' ) ;
    copy( catfile('t', 'testdata', 'data1.txt'), $dest);

    my $expected_mdtm = ( stat $dest )[9];
    $ftp->cwd('dir1');
    is( $ftp->mdtm("data1.txt"), $expected_mdtm );
    unlink catfile('tmp', 'ftpserver', 'dir1', 'data1.txt' );
    done_testing();
};

done_testing();

