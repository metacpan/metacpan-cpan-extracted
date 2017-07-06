#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile catdir rootdir);
use FindBin;
use lib $FindBin::Bin;
use t::Util;
use Test::Mock::Net::FTP;
use Cwd;
use File::Copy;
use Capture::Tiny qw(capture);

my $data = catfile('t', 'testdata', 'data1.txt');

subtest 'default append', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    $ftp->append($data); #same as put

    my $put_file = catfile($ftp->mock_physical_root, 'dir1', 'data1.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    $ftp->append($data);# append again
    file_contents_ok($put_file, "this is testdata #1\nthis is testdata #1\n");

    unlink($put_file);
    done_testing();
};

subtest 'default append and chdir', sub {
    my $ftp = prepare_ftp();
    my $cwd = getcwd();

    my $data_abs = catfile($cwd, $data);
    chdir 'tmp';
    $ftp->cwd('dir1');
    $ftp->append($data_abs);

    my $put_file = catfile($ftp->mock_physical_root, 'dir1', 'data1.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    $ftp->append($data_abs);# append again
    file_contents_ok($put_file, "this is testdata #1\nthis is testdata #1\n");

    unlink($put_file);
    chdir $cwd;
    done_testing();
};


subtest 'specify remote filename', sub {
    my $ftp = prepare_ftp();
    $ftp->append( $data, catfile('dir2', 'data1_another_name.txt') );

    my $put_file = catfile($ftp->mock_physical_root, 'dir2', 'data1_another_name.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    $ftp->append( $data, catfile('dir2', 'data1_another_name.txt') );
    file_contents_ok($put_file, "this is testdata #1\nthis is testdata #1\n");

    unlink($put_file);
    done_testing();
};



subtest 'specify absolute path', sub {
    my $ftp = prepare_ftp();
    $ftp->append( $data, '/ftproot/dir2/data1_another_name2.txt' );

    my $put_file = catfile($ftp->mock_physical_root, 'dir2', 'data1_another_name2.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    $ftp->append( $data, '/ftproot/dir2/data1_another_name2.txt' );
    file_contents_ok($put_file, "this is testdata #1\nthis is testdata #1\n");

    unlink($put_file);
    done_testing();
};

subtest 'error', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    my $ret;
    my ($stdout, $stderr) = capture {
        $ret = $ftp->append('no_exist_file.txt');
    };
    like( $stderr, qr/\ACannot open Local file no_exist_file\.txt:/ms);
    is( $ret, undef);
    done_testing();
};


done_testing();
