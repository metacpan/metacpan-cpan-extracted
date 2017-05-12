package Test::Nightly::Test;

use strict;
use warnings;

use Carp;
use File::Spec;
use List::Util qw(shuffle);
use Test::Harness::Straps;

use Test::Nightly;
use Test::Nightly::Email;

use base qw(Test::Nightly::Base Class::Accessor::Fast);

my @methods = qw(
	build_type
    modules
	test_directory_format
	test_file_format 
	test_order
	tests 
	install_module
	skip_tests
);

__PACKAGE__->mk_accessors(@methods);

our $VERSION = '0.03';

=head1 NAME

Test::Nightly::Test - Make and runs your tests.

=head1 DESCRIPTION

Designed to run our tests, and then store the results back into the object. You probably should not be dealing with this module directly.

=head1 SYNOPSIS

  use Test::Nightly::Test;

  my $test = Test::Nightly::Test->new();

  $test->run();

The following methods are available:

=cut

=head2 new()

  my $test = Test::Nightly::Test->new({
    modules               => \@modules,        # Required.
    build_type            => 'make'            # || 'build'. 'make' is default.
	install_module        => 'all',            # || 'passed'. 'all' is default. 
    skip_tests            => 1,                # skips the tests.
    test_directory_format => ['t/', 'tests/'], # Optional, defaults to ['t/'].
    test_file_format      => ['.t', '.pl'],    # Optional, defaults to ['.t'].
    test_order            => 'ordered',        # || 'random'. 'ordered' is default.
  });

Create a new Test::Nightly::Test object.

C<modules> is an array of the hash refs that include the path to the module and the build script name. It isn't required that you supply this because the directories are found from the Test::Nightly object. Basically you probably shouldn't be calling this package on it's own, rather use the Test::Nightly as your interface, but if you really want to you can.

The rest of the inputs are described below in the List of Methods.

=cut

sub new {

    my ($class, $conf) = @_;

	my $self = bless {}, $class;

	$self->_init($conf, \@methods);
		
	croak 'Test::Nightly::Test::new() - "modules" must be supplied' unless ($self->modules());

	$self->test_directory_format(['t/'])	unless ($self->test_directory_format());
	$self->test_file_format(['.t']) 		unless ($self->test_file_format());
	$self->build_type('make') 				unless ($self->build_type());
	$self->test_order('ordered')			unless ($self->test_order());

	return $self;

}

=head2 run()

  $test->run({
    # ... can take the same arguments as new() ... 
  });

Loops through the supplied modules, makes those modules and runs their tests.

=cut

sub run {

    my ($self, $conf) = @_;

	unless (ref($self->test_directory_format()) eq 'ARRAY') {
		croak "Test::Nightly::Test::run(): Supplied 'test_directory_format' must be an array reference";
	} 
	unless (ref($self->test_file_format()) eq 'ARRAY') {
		croak "Test::Nightly::Test::run(): Supplied 'test_file_format' must be an array reference";
	} 
	unless ($self->build_type() =~ /^(build|make)$/) {
		croak "Test::Nightly::Test::run(): Supplied 'build_type' can only be 'build' or 'make'";
	}

	if ($self->build_type() eq 'build') {
		require Module::Build;
	}
		
	# New strap
	my $strap = Test::Harness::Straps->new;

	my %tests;
	if (scalar @{$self->modules()}) {

		foreach my $module (@{$self->modules()}) {

			# Check if dir exists			
			my $chdir_result = chdir($module->{'directory'});
			unless ($chdir_result) {
				carp 'Test::Nightly::Test::run(): Unable to change directory to: '.$module->{'directory'}.', skipping';
				next;
			}

			# E.g. "perl Makefile.PL"
			my $build_command = $self->_perl_command().' '.$module->{build_script};
			`$build_command`;

			# E.g. "make"
			my $run_build = $self->_run_build();
			`$run_build`;

			my $all_tests_passed = 1;

			# Loop through each test_path that has been passed in
			unless (defined $self->skip_tests()) {

				foreach my $test_path (@{$self->test_directory_format()}) {

					$self->_debug('Current test path is: ' . $test_path);

					# Loop through each test extention that has been passed in
					foreach my $test_ext (@{$self->test_file_format()}) {

						# Strip out the leading slash just so we won't get a double slash
						my $full_path = File::Spec->canonpath($module->{directory} . $test_path);

						if(-d $test_path) {
			
							$self->_debug('Looking for tests that match the extention: ' . $test_ext.' in the path: ' . $test_path);

							# Find all the tests matching the test extention that are in the directory specified.
							my $test_rule = File::Find::Rule->new;
							$test_rule->name( '*' . $test_ext);
							my @found_tests = $test_rule->in($test_path);


							# By default, we wish to run the tests in order. The user can pass in a flag to get them to run at random.
							if ($self->test_order() eq 'random') {
								# Sort randomly with List::Util
								@found_tests = shuffle @found_tests
							} else {
								# Sort numerically ascending
								@found_tests = sort @found_tests;	
							}

							# Run through each test individually, so our report is more specific.
							foreach my $test (@found_tests) {

								# Just in case we picked up the build script as a 'test'
								if ($test =~ /$module->{'build_script'}$/i) {
									next;
								}
						
								# Grab the perl comment to run the test
								my $perl = $self->_perl_command();

								# Run the test, grab the output.
								my $output = `$perl $test 2>&1`;

								# Turn it into an array of lines, because that is what Test::Harness::Straps likes
								my @output = split("\n", $output); 

								# Get Test::Harness::Straps to analyze the output of the test
								my %results = $strap->analyze('test', \@output);

								# Put test into hash for our data structure
								my %single_test = (
									test => $test,
								);
								
								if ($results{passing}) {
									$single_test{'status'} = 'passed';
									$self->_debug('Test in path ['.$full_path.'] ['.$test.'] passed');
								} else {
									$all_tests_passed = undef;
									$single_test{'status'} = 'failed';
									$self->_debug('Test in path ['.$full_path.'] ['.$test.'] failed');
								}

								push (@{$tests{$full_path}}, \%single_test);
								
							}

						}

					}

				}
			
			}

			# E.g. "make install"
			my $install_build = $self->_install_build();

			if (defined $self->install_module()) {
				
				if ($self->install_module() eq 'all') {
					# Install the module, we don't care if the tests passed or failed.
					`$install_build`;
				} elsif ($self->install_module() eq 'passed' and $all_tests_passed) {
					# Install the module, only if it's tests pass. If you choose not to run the tests, this will probably install.
					`$install_build`;
				}
			}

			# E.g. "make clean"
			my $clean_build = $self->_clean_build();
			`$clean_build`;

		}

		$self->tests(\%tests);

	}

}

# Extract out only the passed tests from tests()

sub passed_tests {

    my $self = shift;

	my %passed_tests;
	if (defined $self->tests()) {

		foreach my $module (keys %{$self->tests()}) {

			foreach my $tests ($self->tests()->{$module}){

				foreach my $test (@{$tests}) {

					if ($test->{'status'} eq 'passed') {
						push (@{$passed_tests{$module}}, $test);
					}
				}
			}
		}


	} 

	if ( scalar keys %passed_tests ) {
		return \%passed_tests;
	} else {
		return undef;
	}

}

# Extract out only the failed tests from tests()

sub failed_tests {

    my $self = shift;

	my %failed_tests;
	if (defined $self->tests()) {

		foreach my $module (keys %{$self->tests()}) {

			foreach my $tests ($self->tests()->{$module}){

				foreach my $test (@{$tests}) {

					if ($test->{'status'} eq 'failed') {
						push (@{$failed_tests{$module}}, $test);
					}
				}
			}
		}
	} 

	if ( scalar keys %failed_tests ) {
		return \%failed_tests;
	} else {
		return undef;
	}

}


# Returns the correct build command. E.g. 'make'.


sub _run_build {

	my $self = shift;

	if ($self->build_type() eq 'build') {
		return $self->_perl_command().' Build' if $self->{_is_win32};
		return './Build';
	} else {
		# Default to make
		return 'nmake' if $self->{_is_win32};
		return 'make -s';
	}

}

# Returns the correct install command. E.g. 'make install'.

sub _install_build {

	my $self = shift;

	if ($self->build_type() eq 'build') {
		return $self->_perl_command().' Build install' if $self->{_is_win32};
		return './Build install';
	} else {
		# Default to make
		return 'nmake install' if $self->{_is_win32};
		return 'make -s';
	}
}

# Returns the correct clean command. E.g. 'make clean'.

sub _clean_build {

	my $self = shift;

	if ($self->build_type() eq 'build') {
		return $self->_perl_command().' Build clean' if $self->{_is_win32};
		return './Build clean';
	} else {
		# Default to make
		return 'nmake clean' if $self->{_is_win32};
		return 'make -s clean';
	}

}

=head1 List of methods:

=over 4

=item build_type

Pass this in so we know how you build your modules. There are two options: 'build' and 'make'. Defaults to 'make'.

=item install_module

Pass this in if you wish to have the module installed.

=item modules

List of modules. Usually is generated when you call L<Test::Nightly> new method, however it is possible to pass it in directly here. 
Structure is like so:

@modules = (
  {
    'directory'   => '/dir/to/module01/',
    'build_script' => 'Makefile.PL',
  },
  {
    'directory'   => '/dir/to/module02/',
    'build_script' => 'Makefile.PL',
  },
);

=item skip_tests

Pass this in if you wish to skip running the tests.

=item test_directory_format
  
An array ref of what format the test directories can be. By default it searches for the tests in 't/'.

=item test_file_format 

An array ref of the test file formats you have. e.g. @file_formats = ('.pl', '.t'); Defaults to ['.t'].

=item test_order

Pass this in if you wish to influence the way the tests are run. Either 'ordered' or 'random'. Detauls to 'ordered'.

=item tests

Where the output is stored after running the tests.

=head1 TODO

Find a way to suppress the output while the tests are running.

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 SEE ALSO

L<Test::Nightly>,
L<Test::Nightly::Test>,
L<Test::Nightly::Report>,
L<Test::Nightly::Email>,
L<Test::Nightly::Version>,
L<Test::Nightly::Coverage>,
L<perl>.

=cut

1;

