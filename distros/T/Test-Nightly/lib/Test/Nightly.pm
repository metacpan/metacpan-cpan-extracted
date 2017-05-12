package Test::Nightly;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp;
use File::Spec;
use File::Find::Rule;

use Test::Nightly::Test;
use Test::Nightly::Email;
use Test::Nightly::Report;

use base qw(Test::Nightly::Base Class::Accessor::Fast);

my @methods = qw(
	base_directories
	email_report
	build_script
	build_type
    modules
	report_output
	report_template
    test
	test_directory_format
	test_file_format
	test_report
    version_result
	install_module
	skip_tests
);

__PACKAGE__->mk_accessors(@methods);
my @run_these = qw(version_control run_tests coverage_report generate_report);

=head1 NAME

Test::Nightly - Run all your tests and produce a report on the results.

=head1 DESCRIPTION

The idea behind this module is to have one script, most probably a cron job, to run all your tests once a night (or once a week). This module will then produce a report on the whether those tests passed or failed. From this report you can see at a glance what tests are failing. This is alpha software! Please try it out, email me bugs suggestions etc.

=head1 SYNOPSIS

 # SCENARIO ONE #

  Pass in all the options direct into the constructor.

  use Test::Nightly;

  my $nightly = Test::Nightly->new({
    base_directories => ['/base/dir/from/which/to/search/for/modules/'],
    run_tests     => {},
    generate_report => {
        email_report => {
            to      => 'kirstinbettiol@gmail.com',
        },
        report_output => '/report/output/dir/test_report.html',
    },
    debug           => 1,
  });

 # SCENARIO TWO #

  Call each method individually.

  use Test::Nightly;

  my $nightly = Test::Nightly->new({
    base_directories => ['/base/dir/from/which/to/search/for/modules/'],
  });

  $nightly->run_tests();

  $nightly->generate_report({
    email_report => {
  	  to      => 'kirstinbettiol@gmail.com',
    },
    report_output => '/report/output/dir/test_report.html',
  });

  # SCENARIO THREE

  Use build instead of make.

  use Test::Nightly;

  my $nightly = Test::Nightly->new({
    base_directories   => ['/base/dir/from/which/to/search/for/modules/'],
    build_script       => 'Build.PL',
    run_tests          => {
      build_type  => 'build',
    },
  });

=cut

=head2 new()

  my $nightly = Test::Nightly->new({
    base_directories => \@directories,           # Required. Array of base directories to search in.
    build_script     => 'Build.PL',              # Defaults to 'Makefile.PL'.
    run_tests        => {
  	  test_directory_format => ['t/', 'tests/'], # Optional, defaults to 't/'.
  	  test_file_format      => ['.t', '.pl'],    # Optional, defaults to '.t'.
      build_type            => 'make',           # || 'build'. Defaults to 'make'.
      install_module        => 'all',            # || 'passed'. 'all' is default.
      skip_tests            => 1,                # skips the tests.
      test_order            => 'ordered',        # || 'random'. 'ordered' is default.
    },
    generate_report => {
  	  email_report    => \%email_config,                # Emails the report. See L<Test::Nightly::Email> for config.
  	  report_template => '/dir/somewhere/template.txt', # Defaults to internal template.
  	  report_output   => '/dir/somewhere/output.txt',   # File to output the report to.
  	  test_report     => 'all',                         # 'failed' || 'passed'. Defaults to all.
    },
  });

This is the constructor used to create the main object.

Does a search for all modules on your system, matching the build script description (C<build_script>). You can choose to run all your tests and generate your report directly from this module, by supplying C<run_tests> and C<generate_report>. Or you can simply supply C<base_directories> and it call the other methods separately. 

=cut

sub new {

    my ($class, $conf) = @_;
		
	my $self = bless {}, $class;

	$self->_init($conf, \@methods);

	if (!defined $self->base_directories()) {
		croak 'Test::Nightly::new() - "base_directories" must be supplied';
	} else {

		$self->build_script('Makefile.PL') unless defined $self->build_script();

		$self->_find_modules();

		# See if any methods should be called from new
		foreach my $run (@run_these) {

			if(defined $conf->{$run}) {
				# user wants to run this one
				$self->$run($conf->{$run});
			}
		}

		return $self;

	}

}

=head2 run_tests()

  $nightly->run_tests({
    build_type            => 'make'            # || 'build'. 'make' is default.
    install_module        => 'all',            # || 'passed'. 'all' is default.
    skip_tests            => 1,                # skips the tests.
    test_directory_format => ['t/', 'tests/'], # Optional, defaults to ['t/'].
    test_file_format      => ['.t', '.pl'],    # Optional, defaults to ['.t'].
    test_order            => 'ordered',        # || 'random'. 'ordered' is default.
  });

Runs all the tests on the directories that are stored in the object.

Results are stored back in the object so they can be reported on.

=cut

sub run_tests {

	my ($self, $conf) = @_;

	$self->_init($conf, \@methods);

	my $test = Test::Nightly::Test->new($self);

	$test->run();

	$self->test($test);
	
}

=head2 generate_report()

  $nightly->generate_report({
    email_report    => \%email_config,                # Emails the report. See L<Test::Nightly::Email> for config options.
    report_template => '/dir/somewhere/template.txt', # Defaults to internal template.
    report_output   => '/dir/somewhere/output.txt',   # File to output the report to.
    test_report     => 'all',                         # 'failed' || 'passed'. Defaults to all.
  });

Based on the methods that have been run, produces a report on these. 

Depending on what you pass in, defines what report is generated. If you pass in an email address to L<email_report> then the report will be
emailed. If you specify an output file to C<report_output> then the report will be outputted to that file. 
If you specify both, then both will be done. 

Default behavior is to use the internal template that is in L<Test::Nightly::Report::Template>, however you can overwrite this with your own template (C<report_template>). Uses Template Toolkit logic.

=cut

sub generate_report {

    my ($self, $conf) = @_;

	$self->_init($conf, \@methods);

	my $report = Test::Nightly::Report->new($self);	

	$report->run();

}

sub _find_modules {

    my ($self, $conf) = @_;

    if ($self->build_script() =~ /\s/) {
        croak 'Test::Nightly::_find_modules(): Supplied "build_script" can not contain a space';
    }

	my @modules;

	# Search through all the base directories supplied.
	foreach my $dir (@{$self->base_directories()}) {

		# Continue if that directory exists
		if (-d $dir) {
			
			# Search for files matching the build script description.
			my @found_build_scripts = File::Find::Rule->file()->name( $self->build_script() )->in($dir);

			# do i need to do this?
			foreach my $found_build_script (@found_build_scripts) {

				my ($volume, $directory, $build_script) = File::Spec->splitpath( $found_build_script );
				
				my %module;
				$module{'directory'} = $directory;
				$module{'build_script'} = $build_script;
				
				push(@modules, \%module);

			}

		} else {
			carp 'Test::Nightly::_find_modules() - directory: "'.$dir.'" is not a valid directory';
			next;
		}

	}

    $self->modules(\@modules);

}

=head1 List of methods:

=over 4

=item base_directories

Required. Array ref of base directories to search in.

=item build_script

Searches for the specified build_script names. Defaults to Makefile.PL

=item build_type

Pass this in so we know how you build your modules. There are two options: 'build' and 'make'. Defaults to 'make'.

=item debug

Turns debugging messages on or off.

=item email_report

If set will email the report. Takes a hash ref of \%email_config, refer to Test::Nightly::Email for the options.

=item install_module

Pass this in if you wish to have the module installed.

=item modules

List of modules that have been found, returns an array ref of undef.

=item skip_tests

Pass this in if you wish to skip running the tests.

=item report_output

Set this to a file somewhere and the report will be outputted here.

=item report_template

Pass this in if you wish to use your own customised report template. Otherwise uses the default template is in Test::Nightly::Report::Template

=item test

Holds the Test::Nightly::Test object.

=item test_directory_format

An array of what format the test directories can be. By default it searches for the tests in 't/'

=item test_file_format

An array of the test file formats you have.

=item test_report

This is where you specify what you wish to report on after the outcome of the test. Specifying 'passed' will only report on tests that passed, specifying 'failed' will only report on tests that failed and specifying 'all' will report on both.

=item test_order

Pass this in if you wish to influence the way the tests are run. Either 'ordered' or 'random'. Detauls to 'ordered'.

=back

=head1 DISCLAIMERS

This module assumes that you only need installed modules to test your module. So if the module you're testing requires the changes you've made to another module in the tree that you haven't installed, testing will fail.

If your module asks interactive questions in the build script or test scripts then this won't work.

=head1 TODO

Soon I would like to implement a module that will handle version control, so you are able to checkout and update your modules for testing. As well as this it would be nice to incorporate in a wrapper for L<Devel::Cover>.

L<Test::Nightly::Version>,
L<Test::Nightly::Coverage>.

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 SEE ALSO

L<Test::Nightly>, 
L<Test::Nightly::Test>, 
L<Test::Nightly::Report>, 
L<Test::Nightly::Email>, 
L<perl>.

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 THANKS

Thanks to Leo Lapworth <LLAP@cuckoo.org> for helping me with this and Foxtons for letting me develop this on their time.

=cut

1;

