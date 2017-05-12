#!/usr/bin/perl -w
use Test::More;
use Test::Mock::Net::FTP;
use lib '.';
use t::Util;
use strict;
use warnings;
use File::Spec::Functions qw(abs2rel);
use Cwd;

subtest 'default directory', sub {
    my $ftp = prepare_ftp();

    is( $ftp->pwd, '/ftproot' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver' );
    ok( -d $ftp->mock_pwd);
    is( abs2rel($ftp->mock_physical_root), 'tmp/ftpserver' );

    $ftp->quit;
    done_testing();
};

subtest 'chdir to dir1', sub {
    my $ftp = prepare_ftp();

    ok( $ftp->cwd('dir1') );
    is( $ftp->pwd, '/ftproot/dir1' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1' );
    is( abs2rel($ftp->mock_physical_root), 'tmp/ftpserver' );#physical root is unchange

    $ftp->quit();
    done_testing();
};

subtest 'chdir to dir1 And local dir changed', sub {
    my $ftp = prepare_ftp();

    my $cwd = getcwd();
    chdir 'tmp';
    ok( $ftp->cwd('dir1') );
    is( $ftp->pwd, '/ftproot/dir1' );
    is( abs2rel($ftp->mock_pwd), 'ftpserver/dir1' );
    is( abs2rel($ftp->mock_physical_root), 'ftpserver' );

    chdir $cwd;
    $ftp->quit();
    done_testing();
};

subtest 'back to rootdir', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    ok( $ftp->cwd() );
    is( $ftp->pwd, '/ftproot' ); #back to rootdir
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver');

    $ftp->quit();
    done_testing();
};

subtest 'chdir to updir', sub {
    my $ftp = prepare_ftp();

    ok( $ftp->cwd('dir1/dir2') );
    is( $ftp->pwd, '/ftproot/dir1/dir2' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1/dir2' );

    $ftp->cwd('../../');
    is( $ftp->pwd, '/ftproot' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver' );

    $ftp->quit();
    done_testing();
};

subtest 'chdir to updir using cdup', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1/dir2');

    ok( $ftp->cdup() );
    is( $ftp->pwd, '/ftproot/dir1' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1' );

    $ftp->quit();
    done_testing();
};

subtest 'chdir to up another dir', sub {
    my $ftp = prepare_ftp();

    ok( $ftp->cwd('dir1/dir2') );
    is( $ftp->pwd, '/ftproot/dir1/dir2' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1/dir2' );
    $ftp->cwd('../dir3');
    is( $ftp->pwd, '/ftproot/dir1/dir3' );
    is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1/dir3' );

    $ftp->quit();
    done_testing();
};

subtest 'absolute path', sub {

    subtest 'starting at root' => sub {
        my $ftp = prepare_ftp();

        ok( $ftp->cwd('/ftproot/dir1/dir2') );
        is( $ftp->pwd, '/ftproot/dir1/dir2' );
        is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1/dir2' );

        $ftp->quit();
        done_testing();
    };


    subtest 'starting below root', sub {

        my $ftp = prepare_ftp();

        ok( $ftp->cwd('dir1/dir2') );
        is( $ftp->pwd, '/ftproot/dir1/dir2' );

        ok( $ftp->cwd('/ftproot/dir1/dir2') );
        is( $ftp->pwd, '/ftproot/dir1/dir2' );

        is( abs2rel($ftp->mock_pwd), 'tmp/ftpserver/dir1/dir2' );

        $ftp->quit();
        done_testing();
    };

};



subtest 'invalid path', sub {
    my $ftp = prepare_ftp();

    ok( !$ftp->cwd('dir1/hoge') );
    is( $ftp->message, 'Failed to change directory.');
    is( $ftp->pwd(), '/ftproot' ); #directory wasn't change

    $ftp->quit();
    done_testing();
};


done_testing();
