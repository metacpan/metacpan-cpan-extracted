use strict;

use Test::Builder::Tester;
use Test::More 1;
use Test::File;

require "./t/setup_common";

subtest setup => sub {
	ok( defined &Test::File::_dm_skeleton, "_dm_skeleton is defined" );
	};

my $readable  = 'readable';
my $not_there = 'not_there';
my $test_name = 'This is my test name';

subtest fake_non_multi_user_dm_skeleton => sub {
	local $^O = 'dos';
	ok( Test::File::_obviously_non_multi_user(), "Is not multi user" );

	is( Test::File::_dm_skeleton(),           'skip', "Skip on single user systems" );
	is( Test::File::_dm_skeleton($readable),  'skip', "Skip on single user systems" );
	is( Test::File::_dm_skeleton($not_there), 'skip', "Skip on single user systems" );
	};

subtest fake_non_multi_user => sub {
	local $^O = 'MSWin32';
	diag "$^O\n";;
	ok( ! Test::File::_obviously_non_multi_user(), "Is multi user" );
	};

subtest fake_non_multi_user_missing_file => sub {
	local $^O = 'MSWin32';
	ok( ! Test::File::_obviously_non_multi_user(), "Is multi user" );

	test_out( "not ok 1" );
	test_diag(
		"file [$not_there] does not exist\n" .
		"    #   Failed test at $0 line " . line_num(+4) . "."
		);
	Test::File::_dm_skeleton( $not_there );
	test_test();
	done_testing();
	};

subtest fake_non_multi_user_empty => sub {
	local $^O = 'MSWin32';
	ok( ! Test::File::_obviously_non_multi_user(), "Is multi user" );

	test_out( "not ok 1" );
	test_diag(
		"file name not specified\n" .
		"    #   Failed test at $0 line " . line_num(+4) . "."
		);
	Test::File::_dm_skeleton();
	test_test();
	done_testing();
	};

done_testing();
