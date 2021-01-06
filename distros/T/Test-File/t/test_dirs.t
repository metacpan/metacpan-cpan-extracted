use strict;
use warnings;

use Test::Builder::Tester;
use Test::More 0.95;
use Test::File;

use File::Spec::Functions qw(catfile);

require "./t/setup_common";
open FH, '>', catfile( qw(sub_dir subdir_file) ); close FH;


test_out( 'ok 1 - sub_dir is a directory' );
test_out( 'ok 2 - sub_dir really is a directory' );
dir_exists_ok( 'sub_dir' );
dir_exists_ok( 'sub_dir', 'sub_dir really is a directory' );
test_test();

test_out( 'not ok 1 - bmoogle is a directory' );
test_diag( 'Directory [bmoogle] does not exist!' );
test_fail(+1);
dir_exists_ok( 'bmoogle' );
test_test();

test_out( 'not ok 1 - readable is a directory' );
test_diag( 'File [readable] exists but is not a directory!' );
test_fail(+1);
dir_exists_ok( 'readable' );
test_test();

test_out( 'ok 1 - directory sub_dir contains file subdir_file' );
test_out( 'ok 2 - directory sub_dir really contains file subdir_file' );
dir_contains_ok( 'sub_dir', 'subdir_file' );
dir_contains_ok( 'sub_dir', 'subdir_file', 'directory sub_dir really contains file subdir_file' );
test_test();

test_out( 'not ok 1 - directory bmoogle contains file subdir_file' );
test_diag( 'Directory [bmoogle] does not exist!' );
test_fail(+1);
dir_contains_ok( 'bmoogle', 'subdir_file' );
test_test();

test_out( 'not ok 1 - directory sub_dir contains file bmoogle' );
test_diag( 'File [bmoogle] does not exist in directory sub_dir!' );
test_fail(+1);
dir_contains_ok( 'sub_dir', 'bmoogle' );
test_test();


done_testing();

