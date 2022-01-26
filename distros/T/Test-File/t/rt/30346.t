use strict;

use Test::Builder::Tester;
use Test::More 1;

use_ok( 'Test::File' );

use Cwd;

require './t/setup_common';

subtest file_does_not_exist => sub {
	my $file = "no_such_file-" . "$$" . time() . "b$<$>m";

	unlink $file;

	my $name = "$file is not empty";
	test_out( "not ok 1 - $name");
	test_diag(
		"file [$file] does not exist\n" .
		"    #   Failed test '$name'\n".
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_not_empty_ok( $file );
	test_test( $name );
	done_testing();
	};

subtest file_exists_non_zero => sub {
	my $file = 'min_file';
	diag( "File is $file with size " . (-s $file) . " bytes" );

	my $name = "$file is not empty";
	test_out( "ok 1 - $name");
	file_not_empty_ok( $file );
	test_test( $name );
	done_testing();
	};

subtest file_exists_zero_size => sub {
	require File::Spec;
	my $file = 'file_not_empty_ok_test';
	open my $fh, ">", $file;
	truncate $fh, 0;
	close $fh;

	my $name = "$file is not empty";
	test_out( "not ok 1 - $name");
	test_diag(
		"file [$file] exists with zero size\n" .
		"    #   Failed test '$name'\n".
		"    #   at $0 line " . line_num(+5) . "."
		);
	file_not_empty_ok( $file );
	test_test( $name );

	unlink $file;
	done_testing();
	};

done_testing();
