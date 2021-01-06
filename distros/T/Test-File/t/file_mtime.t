use warnings;
use strict;

use Test::Builder::Tester;
use Test::More 0.95;
use Test::File;

require "./t/setup_common";

# Setup test env
my $mtime_file = 'mtime_file';
ok( -e $mtime_file, 'mtime file exists ok' ) or die $!;

my $curtime = time();
my $set_mtime = $curtime-60*10; # 10 minutes ago
my $count = utime($set_mtime,$set_mtime,$mtime_file);
ok( $count, 'utime reports it set mtime' ) or diag explain $count;

my $mtime = ( stat($mtime_file) )[9];
ok ( $mtime == $set_mtime, 'utime successfully set mtime for testing' ) or diag "Got: $mtime, Expected: $set_mtime";


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# file_mtime_age_ok
test_out( 'ok 1 - file_mtime_age_ok success' );
test_out( 'ok 2 - mtime_file mtime within 660 seconds of current time' );
file_mtime_age_ok( $mtime_file, 60*11, 'file_mtime_age_ok success' );
file_mtime_age_ok( $mtime_file, 60*11 );
test_test( 'file_mtime_age_ok success works' );

test_out( 'not ok 1 - mtime_file mtime within 0 seconds of current time' );
file_mtime_age_ok( $mtime_file );
test_test( name => 'file_mtime_age_ok success works', skip_err => 1 );


test_out( 'not ok 1 - file_mtime_age_ok failure' );
test_err( qr/\s*#\s*Filename \[$mtime_file\] [^\n]+\n/ );
test_fail(+1);
file_mtime_age_ok( $mtime_file, 60*9, 'file_mtime_age_ok failure' );
test_test( 'file_mime_age_ok failure works' );

# file_mtime_lt_ok
test_out( 'ok 1 - file_mtime_lt_ok success' );
test_out( 'ok 2 - mtime_file mtime less than unix timestamp ' . time() );
file_mtime_lt_ok( $mtime_file, time(), 'file_mtime_lt_ok success' );
file_mtime_lt_ok( $mtime_file, time() );
test_test( 'file_mtime_lt_ok success works' );

test_out( 'not ok 1 - file_mtime_lt_ok failure' );
test_err( qr/\s*#\s*Filename \[$mtime_file\] [^\n]+\n/ );
test_fail(+1);
file_mtime_lt_ok( $mtime_file, $curtime-60*11, 'file_mtime_lt_ok failure' );
test_test( 'file_mtime_lt_ok failure works' );

# file_mtime_gt_ok
test_out( 'ok 1 - file_mtime_gt_ok success' );
test_out( 'ok 2 - mtime_file mtime is greater than unix timestamp ' . ($curtime-60*11) );
file_mtime_gt_ok( $mtime_file, $curtime-60*11, 'file_mtime_gt_ok success' );
file_mtime_gt_ok( $mtime_file, $curtime-60*11 );
test_test( 'file_mtime_gt_ok success works' );

test_out( 'not ok 1 - file_mtime_gt_ok failure' );
test_err( qr/\s*#\s*Filename \[$mtime_file\] [^\n]+\n/ );
test_fail( +1 );
file_mtime_gt_ok( $mtime_file, $curtime-60*9, 'file_mtime_gt_ok failure' );
test_test( 'file_mtime_gt_ok failure works' );

# Test internal _stat_file function
test_err( qr/\s*#\s*Filename \[.*?\] does not exist!\n/ );
Test::File::_stat_file( 'non-existent-file-12345', 9 );
test_test( '_stat_file on non-existent file works' );

test_err( qr/\s*#\s*Filename not specified!\n/ );
Test::File::_stat_file( undef );
test_test( '_stat_file no file provided works' );

done_testing();
