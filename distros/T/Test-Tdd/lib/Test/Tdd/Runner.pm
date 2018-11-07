package Test::Tdd::Runner;

use strict;
use warnings;
use Filesys::Notify::Simple;
use Test::More;
use Cwd 'cwd';
use File::Find qw(finddepth);

# Ignore warnings for subroutines redefined, source: https://www.perlmonks.org/bare/?node_id=539512
$SIG{__WARN__} = sub{
	my $warning = shift;
	warn $warning unless $warning =~ /Subroutine .* redefined at/;
};


sub run_tests {
	my @test_files = @_;

	my $tb = Test::More->builder;
	eval {
		for my $test_file (@test_files) {
			$tb->reset();
			delete $INC{$test_file};
			require $test_file;
		}
	} or do {
		print $@;
	  }
}


sub clear_cache {
	my @files = @_;
	my @broken_files = grep { !defined $INC{$_} } (keys %INC);
	delete $INC{$_} for @broken_files;

	for my $file (@files) {
		my $is_test = $file =~ m/\.t$/;
		next if $is_test;

		unless (scalar @broken_files) {
			my $module_key = (grep {$INC{$_} eq $file} (keys %INC))[0];
			next unless $module_key;

			delete $INC{$module_key};
		}
		require $file;
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

	print "Running tests...\n";
	run_tests(@test_files);

	my $watcher = Filesys::Notify::Simple->new([@{$watch}, @{$test_files}]);
	while (1) {
		$watcher->wait(
			sub {
				my @files_changed;
				print "\n";
			  FILE: foreach my $event (@_) {
					my $pwd = cwd();
					my $path = $event->{path};
					$path =~ s/$pwd\///g;

					push @files_changed, $path;
					print $path . " changed\n";
				}
				print "\n";
				print "Running tests...\n";
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
