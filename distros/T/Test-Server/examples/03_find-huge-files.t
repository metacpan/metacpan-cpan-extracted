#!/usr/bin/perl

=head1 NAME

find-huge-files.t - look for a huge folders and/or files

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
	find-huge-files:
	    file-size-limit: 100M
	    files-count-limit: 1000 
	    search-folders:
	        - /var/log
	        - /var/cache
	        - /tmp
	    ignore:
	        - /tmp/huge
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';
use Test::Server::Util qw(parse_size format_size);

my $STAT_SIZE = 7;


my $config = LoadFile($Bin.'/test-server.yaml');

plan 'skip_all' => "no configuration sections for 'find-huge-files: search-folders' "
	if (
		not $config
		or not $config->{'find-huge-files'}
		or not $config->{'find-huge-files'}->{'search-folders'}
	);
$config = $config->{'find-huge-files'};

my $file_size_limit   = parse_size($config->{'file-size-limit'} || '100M');
my $files_count_limit = $config->{'files-count-limit'} || 1000;
my %ignore_file_named = map { $_ => 1} @{$config->{'ignore'}}
	if ref $config->{'ignore'} eq 'ARRAY';

exit main();

sub main {
	my $tests = @{$config->{'search-folders'}};
	
	plan 'tests' => $tests;
	
	foreach my $folder (@{$config->{'search-folders'}}) {
		SKIP: {
			skip 'skipping '.$folder.', not found'
				if not -r $folder;
			
			eq_or_diff(
				[ find_huge_files($folder, $file_size_limit, $files_count_limit) ],
				[],
				$folder
			);
		}
	}	
		
	return 0;
}

sub find_huge_files {
	my $filename          = shift;
	my $file_size_limit   = shift;
	my $files_count_limit = shift;
	
	my @huge_files;
	my @files_to_check = ($filename);
	
	while (my $filename = pop @files_to_check) {
		next if exists $ignore_file_named{$filename};
		
		if (-d $filename) {
			opendir(my $dir_handle, $filename) || return;
			
			my $number_of_files = 0;
			while (my $filename_to_check = readdir($dir_handle)) {
				next if $filename_to_check eq '.';
				next if $filename_to_check eq '..';
				
				$number_of_files++;
				push @files_to_check, File::Spec->catfile($filename, $filename_to_check);
			}
			push @huge_files, $filename.' has '.$number_of_files.' files inside'
				if $number_of_files > $files_count_limit;

			closedir($dir_handle);
		}
		elsif (-f $filename) {
			my @stat = stat($filename);
			my $size = $stat[$STAT_SIZE];
			push @huge_files, $filename.' has '.format_size($size).' size'
				if $size > $file_size_limit;
		}
	}
	
	return @huge_files;
}

__END__

=head1 AUTHOR

Jozef Kutej

=cut
