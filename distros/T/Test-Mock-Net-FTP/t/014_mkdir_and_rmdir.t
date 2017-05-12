#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catdir);
use lib '.';
use t::Util;
use Test::Mock::Net::FTP;

subtest 'mkdir and rmdir', sub {
    remove_tree( catdir('tmp', 'dirX') );

    my $ftp = prepare_ftp();

    ok( !-e catdir($ftp->mock_physical_root, 'dirX' ) );

    ok( $ftp->mkdir('dirX') );
    ok( -e catdir($ftp->mock_physical_root, 'dirX' ) );

    ok( $ftp->rmdir('dirX') );
    ok( !-e catdir($ftp->mock_physical_root, 'dirX' ) );

    remove_tree( catdir('tmp', 'dirX') );
};

subtest 'mkdir and rmdir recursive', sub {
    remove_tree( catdir('tmp', 'dirX') );

    my $ftp = prepare_ftp();

    ok( !-e catdir($ftp->mock_physical_root, 'dirX', 'dirY', 'dirZ' ) );
    ok( $ftp->mkdir('dirX/dirY/dirZ', 1) );
    ok( -e catdir($ftp->mock_physical_root, 'dirX', 'dirY', 'dirZ' ) );

    ok( $ftp->rmdir('dirX', 1) );
    ok( !-e catdir($ftp->mock_physical_root, 'dirX', 'dirY', 'dirZ' ) );

    remove_tree( catdir('tmp', 'dirX') );
};

subtest 'error in rmdir', sub {
    my $ftp = prepare_ftp();

    ok( !$ftp->rmdir('no_exist_dir') );
    isnt( $ftp->message, '');

    ok( !$ftp->rmdir('no_exist_dir', 1) );
    isnt( $ftp->message, '');

    done_testing();
};

subtest 'error in mkdir', sub {
    remove_tree( catdir('tmp', 'dirX') );

    my $ftp = prepare_ftp();

    ok( !-e catdir($ftp->mock_physical_root, 'dirX' ) );

    $ftp->mkdir('dirX');
    ok( !$ftp->mkdir('dirX') ); #already exists
    isnt( $ftp->message, '');

    ok( !$ftp->mkdir('dirX', 1) ); #already exists
    isnt( $ftp->message, '');

    remove_tree( catdir('tmp', 'dirX') );
};


done_testing();
