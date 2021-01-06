use strict;

use Test::Builder::Tester;
use Test::More 0.95;
use Test::File;

require "./t/setup_common";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

test_out( 'ok 1 - zero_file is empty' );
file_empty_ok( 'zero_file' );
test_out( 'ok 2 - zero_file really is empty' );
file_empty_ok( 'zero_file', 'zero_file really is empty' );
test_test();

test_out( 'ok 1 - min_file is not empty' );
file_not_empty_ok( 'min_file' );
test_out( 'ok 2 - min_file really is not empty' );
file_not_empty_ok( 'min_file', 'min_file really is not empty' );
test_test();

subtest works => sub {
	my $file = 'min_file';

	file_exists_ok( $file );

	my $actual_size = -s $file;
	my $under_size  = $actual_size - 3;
	my $over_size   = $actual_size + 3;

	cmp_ok( $actual_size, '>', 10, "$file should be at least 10 bytes" );

	test_out( "ok 1 - $file has right size" );
	file_size_ok( $file, $actual_size );
	test_out( "ok 2 - $file really has right size" );
	file_size_ok( $file, $actual_size, "$file really has right size" );
	test_test();

	test_out( "ok 1 - $file is under $over_size bytes" );
	file_max_size_ok( $file, $over_size );
	test_out( "ok 2 - $file really is under $over_size bytes" );
	file_max_size_ok( $file, $over_size, "$file really is under $over_size bytes" );
	test_test();

	test_out( "ok 1 - $file is over $under_size bytes" );
	file_min_size_ok( $file, $under_size );
	test_out( "ok 2 - $file really is over $under_size bytes" );
	file_min_size_ok( $file, $under_size, "$file really is over $under_size bytes" );
	test_test();
	done_testing();
	};

subtest wrong_size => sub {
	my $file = 'min_file';

	file_exists_ok( $file );

	my $actual_size = -s $file;
	my $under_size  = $actual_size - 3;
	my $over_size   = $actual_size + 3;

	cmp_ok( $actual_size, '>', 10, "$file should be at least 10 bytes" );

	test_out( "not ok 1 - $file has right size" );
	test_diag(
		"File [$file] has actual size [$actual_size] not [$under_size]!\n" .
		"    #   Failed test '$file has right size'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_size_ok( $file, $under_size );
	test_test();

	test_out( "not ok 1 - $file is under $under_size bytes" );
	test_diag(
		"File [$file] has actual size [$actual_size] greater than [$under_size]!\n" .
		"    #   Failed test '$file is under $under_size bytes'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_max_size_ok( $file, $under_size );
	test_test();

	test_out( "not ok 1 - $file is over $over_size bytes" );
	test_diag(
		"File [$file] has actual size [$actual_size] less than [$over_size]!\n" .
		"    #   Failed test '$file is over $over_size bytes'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_min_size_ok( $file, $over_size );
	test_test();

	test_out( "not ok 1 - $file is empty" );
	test_diag(
		"File [$file] exists with non-zero size!\n" .
		"    #   Failed test '$file is empty'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_empty_ok( $file );
	test_test();

	test_out( "not ok 1 - zero_file is not empty" );
	test_diag(
		"File [zero_file] exists with zero size!\n" .
		"    #   Failed test 'zero_file is not empty'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_not_empty_ok( 'zero_file' );
	test_test();
	done_testing();
	};

subtest doesnt_work_with_missing_file => sub {
	my $not_there = 'not_there';
	ok( ! -e $not_there, "File [$not_there] doesn't exist (good)" );

	test_out( "not ok 1 - $not_there has right size" );
	test_diag(
		"File [$not_there] does not exist!\n" .
		"    #   Failed test '$not_there has right size'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_size_ok( $not_there, 53 );
	test_test();

	test_out( "not ok 1 - $not_there is under 54 bytes" );
	test_diag(
		"File [$not_there] does not exist!\n" .
		"    #   Failed test '$not_there is under 54 bytes'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_max_size_ok( $not_there, 54 );
	test_test();

	test_out( "not ok 1 - $not_there is over 50 bytes" );
	test_diag(
		"File [$not_there] does not exist!\n" .
		"    #   Failed test '$not_there is over 50 bytes'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_min_size_ok( $not_there, 50 );
	test_test();

	test_out( "not ok 1 - $not_there is empty" );
	test_diag(
		"File [$not_there] does not exist!\n" .
		"    #   Failed test '$not_there is empty'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_empty_ok( $not_there );
	test_test();

	test_out( "not ok 1 - $not_there is not empty" );
	test_diag(
		"File [$not_there] does not exist!\n" .
		"    #   Failed test '$not_there is not empty'\n" .
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_not_empty_ok( $not_there );
	test_test();
	done_testing();
	};

done_testing();
