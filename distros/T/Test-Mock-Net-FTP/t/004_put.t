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
use Capture::Tiny qw(capture);

my $data = catfile('t', 'testdata', 'data1.txt');

subtest 'default put', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    is( $ftp->put($data), 'data1.txt' );

    my $put_file = catfile($ftp->mock_physical_root, 'dir1', 'data1.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    unlink($put_file);
    done_testing();
};

subtest 'default put and chdir', sub {
    my $ftp = prepare_ftp();
    my $cwd = getcwd();

    my $data_abs = catfile($cwd, $data);
    chdir 'tmp';
    $ftp->cwd('dir1');
    $ftp->put($data_abs);

    my $put_file = catfile($ftp->mock_physical_root, 'dir1', 'data1.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    unlink($put_file);
    chdir $cwd;
    done_testing();
};


subtest 'specify remote filename', sub {
    my $ftp = prepare_ftp();
    $ftp->put( $data, catfile('dir2', 'data1_another_name.txt') );

    my $put_file = catfile($ftp->mock_physical_root, 'dir2', 'data1_another_name.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    unlink($put_file);
    done_testing();
};



subtest 'specify absolute path', sub {
    my $ftp = prepare_ftp();
    $ftp->put( $data, '/ftproot/dir2/data1_another_name2.txt' );

    my $put_file = catfile($ftp->mock_physical_root, 'dir2', 'data1_another_name2.txt');
    file_contents_ok($put_file, "this is testdata #1\n");

    unlink($put_file);
    done_testing();
};

subtest 'put_unique', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    $ftp->put($data); # normal put

    my $put_data_1 = catfile($ftp->mock_physical_root, 'dir1', 'data1.txt');
    file_contents_ok($put_data_1, "this is testdata #1\n");

    is( $ftp->put_unique($data), 'data1.txt.1');
    is( $ftp->unique_name,       'data1.txt.1');

    my $put_data_2 = catfile($ftp->mock_physical_root, 'dir1', 'data1.txt.1');
    file_contents_ok($put_data_1, "this is testdata #1\n");# previous file exist
    file_contents_ok($put_data_2, "this is testdata #1\n");#'.1' is added for unique_name

    done_testing();
};

subtest 'error in put', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    my $ret;
    my ($stdout, $stderr) = capture {
        $ret = $ftp->put('no_exist_file.txt');
    };
    like( $stderr, qr/\ACannot open Local file no_exist_file\.txt:/ms);
    is( $ret, undef);
    done_testing();
};

subtest 'error in put_unique', sub {
    my $ftp = prepare_ftp();

    $ftp->cwd('dir1');
    my $ret;
    my ($stdout, $stderr) = capture {
        $ret = $ftp->put_unique('no_exist_file.txt');
    };
    like( $stderr, qr/\ACannot open Local file no_exist_file\.txt:/ms);
    is( $ret, undef);
    is( $ftp->unique_name(), undef);
    done_testing();
};


done_testing();
