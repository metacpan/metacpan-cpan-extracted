#!/usr/bin/perl

use strict;
use warnings;

use Test::Tester;
#use Test::More 'no_plan';
use Test::More tests => 17;

use Test::Dirs;

use FindBin qw($Bin);
use lib "$Bin/lib";


exit main();

sub main {
	my $tmp_dir;
	my $tdir_src3  = File::Spec->catdir($Bin, 'tdirs', 'src3');
	my $tdir_res31 = File::Spec->catdir($Bin, 'tdirs', 'res3.1');
	my $tdir_res32 = File::Spec->catdir($Bin, 'tdirs', 'res3.2');
	
	my $tmp_dir3 = temp_copy_ok($tdir_src3);
	
	check_test(
		sub { dir_cleanup_ok([$tmp_dir3, 'f1', 'f2', 'some-file'], 'removing file and up') }, {
			ok        => 1,
			name      => 'removing file and up',
			diag      => join(
				"\n",
				'Removed:',
				File::Spec->catfile($tmp_dir3, 'f1', 'f2', 'some-file'),
				File::Spec->catfile($tmp_dir3, 'f1', 'f2'),
			),
		},
		'dir_cleanup_ok - do cleanup'
	);
	
	is_dir($tmp_dir3, $tdir_res31);

	check_test(
		sub { dir_cleanup_ok([$tmp_dir3, 'f1', 'f2x'], 'removing folder and up') }, {
			ok        => 1,
			name      => 'removing folder and up',
			diag      => join(
				"\n",
				'Removed:',
				File::Spec->catfile($tmp_dir3, 'f1', 'f2x', '.exists'),
				File::Spec->catfile($tmp_dir3, 'f1', 'f2x'),
				File::Spec->catfile($tmp_dir3, 'f1'),
			),
		},
		'dir_cleanup_ok - do cleanup'
	);
	
	is_dir($tmp_dir3, $tdir_res32);
	
	return 0;
}

