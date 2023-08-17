package Test::Tdd::Runner;

use strict;
use warnings;
use Filesys::Notify::Simple;
use Test::More;
use Cwd 'cwd';
use Cwd 'abs_path';
use File::Find qw(finddepth);
use Class::Refresh;

# Ignore warnings for subroutines redefined, source: https://www.perlmonks.org/bare/?node_id=539512
$SIG{__WARN__} = sub{
	my $warning = shift;
	warn $warning unless $warning =~ /Subroutine .* redefined at/;
};

sub extract_run_command {
	my ($test_definition) = @_;

	if ($test_definition =~ /(runtests\(?.*?\)?)[ \t\n]+unless caller/) {
		return $1;
	}
	return undef;
}

sub run_tests {
	my @test_files = @_;

	my $tb = Test::More->builder;
	eval {
		for my $test_file (@test_files) {
			open FILE, $test_file;
			my $test_definition = join '', <FILE>;
			my $run_command = extract_run_command($test_definition);
			close FILE;

			$tb->reset();
			delete $INC{$test_file};
			require $test_file;

			eval $run_command if $run_command;
		}
	} or do {
		print $@;
	  }
}

my %file_to_module_key_map = ();

sub clear_cache {
	my @files = @_;
	my @broken_files = grep { !defined $INC{$_} } (keys %INC);
	delete $INC{$_} for @broken_files;

	for my $file (@files) {
		my $is_test = $file =~ m/\.t$/;
		next if $is_test;

		my $module_key;
		unless (scalar @broken_files) {
			$module_key = (grep {$INC{$_} eq $file} (keys %INC))[0];

			# If module_key is not found for the changed file, the program could be using a symlink. We need to see
			# any of the entries in %INC is a symlink that points to the changed file.
			if (!defined) {
				if (!exists $file_to_module_key_map{$file}) {
					for my $key (keys %INC) {
						my $val = $INC{$key};

						# If path is symlink and the symlink links to the changed file.
						if (-l $val && abs_path($val) eq $file) {
							$file_to_module_key_map{$file} = $key;
						}
					}
				}

				$module_key = $file_to_module_key_map{$file};
			}

			next unless $module_key;

			delete $INC{$module_key};

			my $class = $module_key;
			$class =~ s/\//::/g;
			$class =~ s/\.pm//g;
			Class::Refresh->unload_module($class);
		}
		require ($module_key || $file);
	}
}

sub expand_folders {
	my @test_files = @_;

	my @expanded_files;
	for my $test (@test_files) {
		if (-d $test) {
			finddepth(
				sub {
					return if($_ eq '.' || $_ eq '..');
					push @expanded_files, $File::Find::name;
				},
				$test
			);
		} else {
			push @expanded_files, $test;
		}
	}

	return grep { !-d } @expanded_files;
}

sub start {
	my ($watch, $test_files) = @_;
	my @test_files = expand_folders @{$test_files};

	$ENV{IS_PROVETDD} = 1;

	print "Running tests...\n";
	run_tests(@test_files);

	print "\nWatching for changes on ", (join ",", @{$watch}), ". Press CTRL+C to stop running tests.\n";
	my $watcher = Filesys::Notify::Simple->new([@{$watch}, @{$test_files}]);
	while (1) {
		$watcher->wait(
			sub {
				my @files_changed;
			  FILE: foreach my $event (@_) {
					my $pwd = cwd();
					my $path = $event->{path};
					$path =~ s/$pwd\///g;
					next if $path =~ /\/\./;

					# Ignore duplicates.
					if (!grep(/^$path$/, @files_changed)) {
						push @files_changed, $path;
						print "\n" . $path . " changed";
					}
				}
				return unless @files_changed;

				print "\n\nRunning tests...\n";
				eval {
					clear_cache(@files_changed);
					run_tests(@test_files);
				} or do {
					print $@;
				}
			}
		);
	}
}

1;
