#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);
my $src_dir = File::Spec->catdir($Bin, 'tdirs', 'src1');

SYNOPSIS: {
	use Test::More tests => 5;
	use Test::Dirs;
	
	# make a temporary copy of a folder
	my $tmp_dir = temp_copy_ok($src_dir, 'copy template to tmp folder');
	
	# compare one folder with another
	is_dir($src_dir, $tmp_dir, 'temp copy should be the same as source');
	
	# set files to ignore
	my @ignore_files = qw(.ignore_me);
	open(my $fh, '>', File::Spec->catfile($tmp_dir, '.ignore_me')) or die $!;
	is_dir($src_dir, $tmp_dir, 'temp copy should be the same as source', \@ignore_files);
	
	TODO: {
		local $TODO = 'do something with the extra file in the future';
		is_dir($src_dir, $tmp_dir, 'fails without @ignore_files');
	};
	
	# be verbose, print out the diff if doesn't match
	is_dir($src_dir, $tmp_dir, 'test with verbose on', \@ignore_files, 'verbose');
};

1;
