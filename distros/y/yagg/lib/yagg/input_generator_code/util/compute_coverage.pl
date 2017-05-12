#!/bin/perl

# Deletes any .gcda files found in the build directories!

# For all mode, the various reports are merged into a "merged format" file
# that I've created. The graph and data lines in the header have all been put
# into the output file, and the programs and runs have been summed. Within the
# code text, the total coverage numbers have been added, and extra lines
# appended from each original file. You can still parse the coverage results
# by looking for my ($marker,$line_number,$data) = $line =~ /^([^:]+):([\d\s]+):(.*)/.
# If the second : is a -, then it's an informational line.

# Note that some merging may occur for .h coverage files even if you are
# running only one test case, as they are included into multiple files whose
# coverage is measured.

use warnings;
use strict;

use File::Spec::Functions;
use File::Temp;
use File::Find;
use File::Path qw( rmtree mkpath );
use Cwd qw( realpath getcwd);

my $CWD;

{
	$CWD = getcwd();

	my ($tests, $opts) = initialize();

#use Data::Dumper;
#print Dumper $opts;
#die Dumper $tests;

	my $output_coverage_dir = $$opts{'o'};
	my @dirsets = @{ $$opts{'d'} };


	if ($$opts{'C'}) {
		foreach my $dirset (@dirsets) {
			my @gcda_files = find_files($dirset->{'object'}, 'gcda');
			if (@gcda_files) {
				print "Deleting coverage information in $dirset->{'object'}\n";
				unlink @gcda_files;
			}
		}
	}

	run_tests($tests);


	foreach my $dirset (@dirsets) {
		unlink <*.gcov>;

		foreach my $gcda_filepath (find_files($dirset->{'object'}, 'gcda')) {
			my $gcda_path = dirname($gcda_filepath);
			my $gcda_file = basename($gcda_filepath);

			# gcov expects us to be in the build directory :(
			chdir $dirset->{'build'};

			system "gcov -o '$gcda_path' '$gcda_file' >/dev/null";

			save_or_delete_gcov_files($dirset->{'build'}, \@dirsets,
				$output_coverage_dir);
		}
	}
}

#-------------------------------------------------------------------------------

sub initialize {
	my %opts;

	die usage() unless getopt(\%opts);
	
	my @tests = @ARGV;

	# Make all paths absolute
	foreach my $dirset (@{ $opts{'d'} }) {
		$dirset->{'build'} = smart_rel2abs($dirset->{'build'});
		$dirset->{'source'} = smart_rel2abs($dirset->{'source'});
		$dirset->{'object'} = smart_rel2abs($dirset->{'object'});

		die "WARNING: $dirset->{'build'} for $dirset->{'output_subdir'} does not exist\n"
			 unless -d $dirset->{'build'};
		die "WARNING: $dirset->{'source'} for $dirset->{'output_subdir'} does not exist\n"
			 unless -d $dirset->{'source'};
		die "WARNING: $dirset->{'object'} for $dirset->{'output_subdir'} does not exist\n"
			 unless -d $dirset->{'object'};
	}

	$opts{'o'} = smart_rel2abs($opts{'o'});

	return (\@tests, \%opts);
}

#-------------------------------------------------------------------------------

sub usage {
<<EOF
usage: $0 [-C] -d <module name> <source dir> <object dir> <build dir> [-d ...]
	-o <output dir> [tests or programs]

-C Clear any existing coverage data from previous runs before running the
   tests or programs
-d Specify the module name, source directory, object directory, and build
   directory for each module. For example:
	 -d fa_solver_library ../fa_solver/src ../fa_solver/build ../fa_solver
-o Specify the output directory for the coverage reports
EOF
}

#-------------------------------------------------------------------------------

sub run_tests {
	my @tests = @{ shift @_ };

	if (@tests) {
		foreach my $test (@tests) {
			print "Running test \"$test\"...\n";
			system "$test 1>/dev/null 2>/dev/null";
		}
	} else {
		print "No tests specified. Run your test now manually and press enter when done.";
		<STDIN>;
	}
}

#-------------------------------------------------------------------------------

sub save_or_delete_gcov_files {
	my $build_dir = shift @_;
	my @dirsets = @{ shift @_ };
	my $test_coverage_dir = shift;

	my @gcov_files = <*.gcov>;

	foreach my $gcov_file (@gcov_files) {
		my ($dirset,$original_source_file) =
			find_dirset_and_source_file($gcov_file,$build_dir,\@dirsets);

		next unless defined($dirset);

		my $original_relative_source_file =
			File::Spec->abs2rel($original_source_file,$dirset->{'build'});

		my $destination_dir =
			dirname("$test_coverage_dir/$dirset->{'output_subdir'}/$original_relative_source_file");

		mkpath $destination_dir;

		if (-e "$destination_dir/$gcov_file") {
			make_merged_format_file("$destination_dir/$gcov_file");
			merge_into_existing_file($gcov_file,"$destination_dir/$gcov_file");
		} else {
			system "mv '$gcov_file' '$destination_dir/$gcov_file'";
		}
	} continue {
		unlink $gcov_file;
	}
}

#-------------------------------------------------------------------------------

sub find_dirset_and_source_file {
	my $input_gcov_file = shift;
	my $build_dir = shift @_;
	my @dirsets = @{ shift @_ };

	open IN_GCOV, $input_gcov_file;

	my $original_relative_source_file;

	while (my $line = <IN_GCOV>) {
		if ($line =~ /^\s*-:\s*0:Source:(.*)/) {
			$original_relative_source_file = $1;
			last;
		}
	}

	close IN_GCOV;

	die "Couldn't find source file in preamble\n"
		unless defined $original_relative_source_file;

	my $original_abs_source_file =
		smart_rel2abs($original_relative_source_file,$build_dir);

	foreach my $dirset (@dirsets) {
		return ($dirset,$original_abs_source_file)
			if is_subdirectory($original_abs_source_file,$dirset->{'build'});
	}

	return undef;
}

#-------------------------------------------------------------------------------

# Does nothing if the file is already in merged format.
sub make_merged_format_file {
	my $gcov_file = shift;

	my $output = '';
	my $data_file;

	open IN_GCOV, $gcov_file;

	while (my $line = <IN_GCOV>) {
		$output .= $line;

		if ($line =~ /^\s*(\d+):\s*\d+-Data:/) {
			close IN_GCOV;
			return;
		} elsif ($line =~ /^\s*-:\s*0:Data:(.*)\n/) {
			$data_file = $1;
		} elsif ($line =~ /^\s*(\d+):\s*\d+:/) {
			(my $new_line = $line) =~ s/(:.*?):(.*)\n/$1-Data:$data_file\n/;
			$output .= $new_line;
		}
	}

	close IN_GCOV;

	open OUT_GCOV, ">$gcov_file";
	print OUT_GCOV $output;
	close OUT_GCOV;
}

#-------------------------------------------------------------------------------

sub merge_into_existing_file {
	my $input_gcov_file = shift;
	my $target_gcov_file = shift;

	my $data_file_1;
	my $output = '';

	open IN_GCOV, $input_gcov_file;
	open IN_MERGED_GCOV, $target_gcov_file;

	my $line_1 = <IN_GCOV>;
	my $line_2 = <IN_MERGED_GCOV>;

	while (!eof(IN_GCOV) && !eof(IN_MERGED_GCOV)) {
#print "----------------------------------------\n$line_1$line_2";
		my ($marker_1,$line_number_1,$data_1) = $line_1 =~ /^([^:]+):([\d\s]+):(.*)/;
		my ($marker_2,$line_number_2,$divider_2,$data_2) =
			$line_2 =~ /^([^:]+):([\d\s]+)([:-])(.*)/;

		if ($divider_2 eq '-') {
			$output .= $line_2;
			$line_2 = <IN_MERGED_GCOV>;
			next;
		}

		if ($line_number_2 == 0 && $data_2 =~ /^Source:/) {
			$output .= $line_2;
			$line_1 = <IN_GCOV>;
			$line_2 = <IN_MERGED_GCOV>;
			next;
		}

		if ($line_number_2 == 0 && $data_2 =~ /^Graph:/) {
			$output .= $line_2;
			$line_2 = <IN_MERGED_GCOV>;
			next;
		}

		if ($line_number_1 == 0 && $data_1 =~ /^Graph:/) {
			$output .= $line_1;
			$line_1 = <IN_GCOV>;
			next;
		}

		if ($line_number_2 == 0 && $data_2 =~ /^Data:/) {
			$output .= $line_2;
			$line_2 = <IN_MERGED_GCOV>;
			next;
		}

		if ($line_number_1 == 0 && $data_1 =~ /^Data:(.*)/) {
			$data_file_1 = $1;
			$output .= $line_1;
			$line_1 = <IN_GCOV>;
			next;
		}

		if ($line_number_1 == 0 && $line_number_2 == 0) {
			if ($data_1 =~ /^Runs:/ && $data_2 =~ /^Runs:/) {
				my ($num_1) = $data_1 =~ /^Runs:(\d+)/;
				my ($num_2) = $data_2 =~ /^Runs:(\d+)/;

				my $new_num = sprintf('%' . length($num_2) . 's', $num_1 + $num_2);
				$output .= "$marker_2:$line_number_2:Runs:$new_num\n";

				$line_1 = <IN_GCOV>;
				$line_2 = <IN_MERGED_GCOV>;
				next;
			}

			if ($data_1 =~ /^Programs:/ && $data_2 =~ /^Programs:/) {
				my ($num_1) = $data_1 =~ /^Programs:(\d+)/;
				my ($num_2) = $data_2 =~ /^Programs:(\d+)/;

				my $new_num = sprintf('%' . length($num_2) . 's', $num_1 + $num_2);
				$output .= "$marker_2:$line_number_2:Programs:$new_num\n";

				$line_1 = <IN_GCOV>;
				$line_2 = <IN_MERGED_GCOV>;
				next;
			}
		}

		if ($line_number_1 == $line_number_2) {
			my $new_marker;

			if ($marker_1 !~ /-/ && $marker_2 =~ /-/) {
				$output .= "$marker_1:$line_number_2:$data_2\n";
			} elsif ($marker_1 =~ /-/) {
				$output .= "$marker_2:$line_number_2:$data_2\n";
			} elsif ($marker_1 !~ /#/ && $marker_2 =~ /#/) {
				$output .= "$marker_1:$line_number_2:$data_2\n";
			} elsif ($marker_1 =~ /#/) {
				$output .= "$marker_2:$line_number_2:$data_2\n";
			} else {
				$new_marker = sprintf('%' . length($marker_2) . 's', $marker_1 + $marker_2);
				$output .= "$new_marker:$line_number_2:$data_2\n";

				(my $new_line = $line_1) =~ s/(:.*?):(.*)\n/$1-Data:$data_file_1\n/;
				$output .= $new_line;
			}

			$line_1 = <IN_GCOV>;
			$line_2 = <IN_MERGED_GCOV>;
			next;
		}

		die "Unexpected state:\n\$line_1: $line_1\$line_2: $line_2\n";
	}

	close IN_GCOV;

	open OUT_GCOV, ">$target_gcov_file";
	print OUT_GCOV $output;
	close OUT_GCOV;
}

#-------------------------------------------------------------------------------

sub find_files {
	my $dir = shift;
	my $extension_pattern = shift;

	my @files;

	find( sub {
		if ($File::Find::name =~ /\.$extension_pattern$/) {
			push @files, $File::Find::name;
		}
	}, $dir);
	
	return @files;
}

#-------------------------------------------------------------------------------

sub dirname {
	my $file_path = shift;

	if ($file_path =~ /(.*)\//) {
		return $1;
	} else {
		return '.';
	}
}

#-------------------------------------------------------------------------------

sub basename {
	my $file_path = shift;

	if ($file_path =~ /.*\/(.*)/) {
		return $1;
	} else {
		return $file_path;
	}
}

#-------------------------------------------------------------------------------

# True if $dir1 is a subdirectory of $dir2
sub is_subdirectory {
	my $dir1 = shift;
	my $dir2 = shift;

	return (File::Spec->abs2rel($dir1,$dir2) !~ /^\.\./);
}

#-------------------------------------------------------------------------------

# Returns the common prefix path of a set of paths. If any path is absolute,
# they are all made absolute before the prefix is computed. In any case, the
# paths will be made canonical (so that, e.g., foo/../bar will become bar).
sub get_common_prefix_path {
	my @paths = @_;

	return undef unless @paths;

	@paths = map { smart_canonpath($_) } @paths;

	if (grep {file_name_is_absolute($_)} @paths) {
		@paths = map { File::Spec->rel2abs( $_, $CWD ) } @paths;
	}


	my @dirs = File::Spec->splitdir( $paths[0] );

	for ( my $i=0; $i <= $#dirs; $i++ ) {
		foreach my $path (@paths) {
			if ((File::Spec->splitdir($path))[$i] ne $dirs[$i]) {
				splice @dirs, $i;
				last;
			}
		}
	}

	return catdir( @dirs );
}

#-------------------------------------------------------------------------------

sub smart_rel2abs {
	my $dir1 = shift;
	my $dir2 = shift;

	$dir2 = $CWD unless defined $dir2;

	return smart_canonpath( File::Spec->rel2abs( $dir1, $dir2 ) );
}

#-------------------------------------------------------------------------------

# This is a smart version of File::Spec->canonpath that collapses foo/../bar
# into bar if possible. (Note that it may not be possible if foo is a symlink
# to some other directory.)
sub smart_canonpath {
	my $path = shift;

	# Do File::Spec's canonpath
	$path = canonpath($path);
	my @dirs = File::Spec->splitdir($path);

	for ( my $i=0; $i <= $#dirs; $i++ ) {
		if ($dirs[$i] eq '..' &&
				realpath(catdir(@dirs[0..$i])) eq realpath(catdir(@dirs[0..$i-2]))) {
			splice @dirs, $i-1, 2;
			$i = $i - 2;
		}
	}

	return catdir( @dirs );
}

#-------------------------------------------------------------------------------

sub getopt {
	my $opts = shift;

	$$opts{'C'} = 0;

	while (@ARGV) {
		if ($ARGV[0] eq '-d') {
			shift @ARGV;
			my ($name, $source, $object, $build) = splice @ARGV, 0, 4, ();
			push @{ $$opts{'d'} }, {
				'output_subdir' => $name,
				'source' => $source,
				'object' => $object,
				'build' => $build
			};
		} elsif ($ARGV[0] eq '-o') {
			shift @ARGV;
			$$opts{'o'} = shift @ARGV;
		} elsif ($ARGV[0] eq '-C') {
			shift @ARGV;
			$$opts{'C'} = 1;
		} elsif ($ARGV[0] =~ /^-/) {
			die usage();
		} else {
			last;
		}
	}

	foreach my $dir_tuple (@{ $$opts{'d'} }) {
		if (!is_subdirectory($dir_tuple->{'source'},$dir_tuple->{'build'})) {
			print "Source directory $dir_tuple->{'source'} should be a subdirectory of build directory $dir_tuple->{'build'}\n";
			return 0;
		}
		unless (-d $dir_tuple->{'source'}) {
			print "Source directory $dir_tuple->{'source'} does not exist\n";
			return 0;
		}
		unless (-d $dir_tuple->{'object'}) {
			print "Object directory $dir_tuple->{'object'} does not exist\n";
			return 0;
		}
		unless (-d $dir_tuple->{'build'}) {
			print "Build directory $dir_tuple->{'build'} does not exist\n";
			return 0;
		}
	}

	return 1;
}
