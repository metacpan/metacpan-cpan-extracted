#!/usr/bin/perl

use strict;
use warnings;

use Test::Tester;
#use Test::More 'no_plan';
use Test::More tests => 38;
use File::is;

use Test::Dirs;

use FindBin qw($Bin);
use lib "$Bin/lib";


exit main();

sub main {
	my $tmp_dir;
	my $tdir_src1 = File::Spec->catdir($Bin, 'tdirs', 'src1');
	my $tdir_src2 = File::Spec->catdir($Bin, 'tdirs', 'src2');
	
	# create a copy of a folder in a temp directory
	check_test(
		sub { $tmp_dir = temp_copy_ok($tdir_src1) }, {
			actual_ok => 1,
			name      => 'copy of '.$tdir_src1,
		},
		'temp_copy_of - create a temp copy'
	);
	
	ok(-d $tmp_dir, 'return value is a folder');
	ok(!File::is->thesame($tdir_src1, $tmp_dir), 'not the same one');
	ok(-d File::Spec->catdir($tmp_dir, 'abc'), 'folder with "abc folder"');
	ok(-f File::Spec->catfile($tmp_dir, 'abc', 'zyx'), 'folder with "abc folder" and "xyz file" inside');

	# compare two identical folders
	check_test(
		sub { is_dir($tdir_src1, $tmp_dir) }, {
			actual_ok => 1,
			name      => 'cmp '.$tdir_src1.' with '.$tmp_dir,
		},
		'is_dir - compare original and copy'
	);

	# compare two folders with different content
	check_test(
		sub { is_dir($tdir_src1, $tdir_src2, 'src1 vs src2') }, {
			ok        => 0,
			name      => 'src1 vs src2',
			diag      => join(
				"\n",
				'Only in '.$tdir_src1.': 123',
				'Only in '.$tdir_src2.': abc/999',
				'File "abc/zyx" differ',
				'File "cba" differ',
				'File "xxx" differ',
			),
		},
		'is_dir - compare two different folders'
	);

	# the diffrent files as ignore will make the test pass
	my @ignore_files = map {
			File::Spec->catfile(@{$_})
		} (
			[123],
			['abc', '999'],
			['abc', 'zyx'],
			['xxx'],         # will be pop-ed out later
			['cba'],         # will be pop-ed out later
	);
	check_test(
		sub { is_dir($tdir_src1, $tdir_src2, 'src1 vs src2 with ignore', \@ignore_files), }, {
			actual_ok => 1,
			name      => 'src1 vs src2 with ignore',
			diag      => '',
		},
		'is_dir - compare original and copy'
	);
	
	# removing one element from @ignore_files should result in failing test
	pop @ignore_files;
	check_test(
		sub { is_dir($tdir_src1, $tdir_src2, 'src1 vs src2 with less ignore', \@ignore_files), }, {
			ok        => 0,
			name      => 'src1 vs src2 with less ignore',
			diag      => 'File "cba" differ',
		},
		'is_dir - compare original and copy'
	);

	# verbose output
	pop @ignore_files;
	my ($premature, @results) = run_tests(
		sub {
			is_dir($tdir_src1, $tdir_src2, 'src1 vs src2 with less ignore', \@ignore_files, 'verbose');
		}
	);
	my $result = $results[0];
	my $result_diag = $result->{'diag'};
	$result_diag =~ s/^([-+]{3}) .+? $/$1/xmsg;
	is(
		$result_diag,
		join("\n",
			'File "cba" differ',
			'in '.$tdir_src1.' is a regular file while in '.$tdir_src2.' is a directory',
			'File "xxx" differ',
			"---",
			"+++",
			'@@ -1,10 +1,10 @@',
			' 1Help',
			' 2Save',
			'-3Mark',
			'+3Mark...',
			' 4Replace',
			' 5Copy',
			' 6Move',
			'-7Search',
			'+7Search...',
			' 8Delete',
			' 9PullDn',
			' 10Quit',
			''
		),
		'xxx files differ (verbose output)'
	);
	
	return 0;
}

