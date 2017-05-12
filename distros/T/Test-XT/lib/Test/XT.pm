package Test::XT;

=pod

=head1 NAME

Test::XT - Generate best practice release-only tests

=head1 SYNOPSIS

  use Test::XT 'WriteXT';
  
  # Write some specific tests:
  WriteXT(
      # Generally safe and recommended for most distributions
      'Test::Pod'            => 'xt/pod.t',
      'Test::CPAN::Meta'     => 'xt/meta.t',
      'Test::MinimumVersion' => 'xt/minimumversion.t',
      'Test::HasVersion'     => 'xt/hasversion.t',
      
      # Controversial history and methodology, does not install reliably.
      # Forced use leads to cargo cult of worse-than-nothing empty method stubs.
      'Test::Pod::Coverage'  => 'xt/podcoverage.t',
      
      # May become unreliable over time as PPI and Perl::Critic change.
      # Safe when BOTH distribution and policy file are active and maintained.
      'Test::Perl::Critic'   => 'xt/critic.t',
      
      # Should only be used if you hand-maintain your MANIFEST file.
      # Can be presumptive about MANIFEST.SKIP in some situations.
      'Test::DistManifest'   => 'xt/distmanifest.t',
      
      # Does not install reliably, does not install AT ALL on Windows.
      'Test::CheckChanges'   => 'xt/changes.t',
  );

=head1 DESCRIPTION

A number of Test modules have been written over the years to support
authors. Typically, these modules have standard short test scripts
documented in them that you can cut and paste into your distribution.

Unfortunately almost all of these cut-and-paste test scripts are wrong.

Either the test script runs during install time, or it runs with an
out-of-date version of the test module, or the author adds the test
modules as an (unnecesary) dependency at install time, or for automated
testing.

B<Test::XT> is a module intended for use in code generators, release
automation and other ancillary systems. It generates an appropriate test
script for various testing modules that runs in the appropriate mode for
each type of execution environment.

1. End User Install

At installation time, test scripts should never ever run, even if the
test modules are installed and available.

2. Automated Testing

  # Enable automated testing
  $ENV{AUTOMATED_TESTING} = 1

During automated testing we should run the tests, but only if the testing
module are already installed and at the current/latest version.

However, we should not install dependencies during automated testing,
because failing to install a testing dependency means B<less> runs
on your code when the entire point of the author tests is to improve
the standard of testing, not reduce it.

3. Release/Author Testing

  # Enable author tests
  $ENV{RELEASE_TESTING} = 1;

All tests should be run at release time by the author. Despite this, the
dependencies should NEVER be added to your F<Makefile.PL> or F<Build.PL>,
because it is far too easy to accidentally have these extra
dependencies bleed through into your published META.yml.

This would cause inaccuracies in tools that track dependencies
across the entire repository via the META.yml files.

=cut

use 5.008;
use strict;
use warnings;
use Exporter ();
use Carp     ();

use vars qw{$VERSION @ISA @EXPORT_OK};
BEGIN {
	$VERSION   = '0.04';
	# $VERSION   = eval $VERSION; # For dev release only
	@ISA       = 'Exporter';
	@EXPORT_OK = qw{
		WriteTest
		WriteXT
	};
}

=pod

=head1 SUPPORTED TEST MODULES

=over

=item * L<Test::Pod>

=item * L<Test::CPAN::Meta>

=item * L<Test::HasVersion>

=item * L<Test::MinimumVersion>

=item * L<Test::Perl::Critic>

=item * L<Test::DistManifest>

=item * L<Test::CheckChanges>

=item * L<Test::Pod::Coverage>

=back

To programmatically extract a list of the relevant module files, or to get
informtion about supported modules, you may directly access the underlying
hash:

  %Test::XT::STANDARD

Please note that this interface is experimental and subject to change.

=cut

# Data for standard tests
our %STANDARD = (
	'Test::Pod' => {
		test    => 'all_pod_files_ok',
		release => 0, # is this a RELEASE test only?
		comment => 'Test that the syntax of our POD documentation is valid',
		modules => {
			'Pod::Simple' => '3.07',
			'Test::Pod'   => '1.26',
		},
		default => 'pod.t',
	},
	'Test::CPAN::Meta' => {
		test    => 'meta_yaml_ok',
		release => 0,
		comment => 'Test that our META.yml file matches the specification',
		modules => {
			'Test::CPAN::Meta' => '0.12',
		},
		default => 'meta.t',
	},
	'Test::HasVersion' => {
		test    => 'all_pm_version_ok',
		release => 0,
		comment => 'Test that all modules have a version number',
		modules => {
			'Test::HasVersion' => '0.012',
		},
		default => 'hasversion.t',
	},
	'Test::MinimumVersion' => {
		test    => 'all_minimum_version_from_metayml_ok',
		release => 0,
		comment => 'Test that our declared minimum Perl version matches our syntax',
		modules => {
			'Perl::MinimumVersion' => '1.20',
			'Test::MinimumVersion' => '0.008',
		},
		default => 'minimumversion.t',
	},
	'Test::Perl::Critic' => {
		test    => 'all_critic_ok',
		release => 1,
		comment => 'Test that the module passes perlcritic',
		modules => {
			'Perl::Critic'       => '1.098',
			'Test::Perl::Critic' => '1.01',
		},
		default => 'critic.t',
	},
	'Test::DistManifest' => {
		test    => 'manifest_ok',
		release => 1,
		comment => 'Test that the module MANIFEST is up-to-date',
		modules => {
			'Test::DistManifest' => '1.003',
		},
		default => 'distmanifest.t',
	},
	'Test::Pod::Coverage' => {
		test    => 'all_pod_coverage_ok',
		release => 1,
		comment => 'Ensure pod coverage in your distribution',
		modules => {
			'Test::Pod::Coverage' => '1.08',
		},
		default => 'podcoverage.t',
	},
	'Test::CheckChanges' => {
		test    => 'ok_changes',
		release => 0,
		comment => 'Test that Changes has an entry for current version',
		modules => {
			'Test::CheckChanges' => '0.08',
		},
		default => 'changes.t',
	},
);





#####################################################################
# Exportable Functions

=pod

=head1 FUNCTIONS

=head2 WriteTest

  WriteTest(
    'xt/something.t',
    test    => 'ok_changes',
    release => 0,
    comment => 'Test that Changes has an entry for current version',
    modules => {
      'Test::CheckChanges' => '0.08',
    },
  );

This function provides a simple way to write a single test to a file,
following the usual template. The test data is a hash (Note: it's NOT a
hash reference).

The example above writes a test to B<xt/somefile.t> that loads L<Test::CheckChanges> if
available, calling the C<ok_changes()> function if it is. A few knobs
control how this works:

=over

=item * B<test> is the name of the subroutine to run, which has to be
exported from the test module.

=item * B<release> determines whether this is a release-only test, which
means it is not executed during automated testing, even if the needed
prerequisites are available.

=item * B<comment> is the default comment which briefly describes the test.

=item * B<modules> is a hash reference containing pairs of modules and
their required versions. If no particular version is required, use 0.

=back

=cut

sub WriteTest {
	my $file = shift;
	Test::XT->new( @_ )->write( $file );
}

=pod

=head2 WriteXT

  WriteXT(
      'Test::Pod'            => 'xt/pod.t',
      'Test::CPAN::Meta'     => 'xt/meta.t',
      'Test::MinimumVersion' => 'xt/minimumversion.t',
      'Test::Perl::Critic'   => 'xt/critic.t',
  );

This provides a convenient way to write multiple test files using the default
profile settings (such as which modules to require, what subroutine to call,
whether this is a release-only test, and so on).

Example code:

=cut

sub WriteXT {
	while ( @_ ) {
		my $module = shift;
		my $file   = shift;

		unless ( $STANDARD{$module} ) {
			Carp::croak('Unknown standard test script ' . $module);
		}

		Test::XT->new(
			%{$STANDARD{$module}}
		)->write( $file );
	}
}





#####################################################################
# Object Form

=pod

=head1 OBJECT ORIENTED INTERFACE

=head2 new

  my $test = Test::XT->new(
    test    => 'all_pod_files_ok',
    release => 0, # is this a RELEASE test only?
    comment => 'Test that the syntax of our POD documentation is valid',
    modules => {
      'Pod::Simple' => '3.07',
      'Test::Pod'   => '1.26',
    },
    default => 'pod.t',
  );

This produces a new object that stores information about a given test module.
It can then be transformed into output suitable for use in a stream (via
C<write_string>, which returns the test script as a string) or for writing
directly to a file (using C<write>).

For details on the available options, see B<WriteTest>

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

=head2 module

  $test->module( 'Foo::Bar' => '1.23' );

Add a module dependency for the test script.

=cut

sub module {
	$_[0]->{modules}->{$_[1]} = $_[2];
}

=head2 test

  $test->test( $command );

Change the name of the subroutine which is called to actually run the test.

Code example:

  $test->test('all_pod_coverage_ok');

=cut

sub test {
	$_[0]->{test} = $_[1];
}

=head2 write

  $test->write( $path )

This method writes the test file to the provided path.

Note that this method throws an exception upon failure to open the file.

Code example:

  eval {
    $test->write('t/file.t');
  };
  print "Failure writing file" if $@;

=cut

sub write {
	my $self   = shift;

	# Write the file
	open( FILE, '>', $_[0 ] ) or Carp::croak("Failed to open file: $!");
	print FILE $self->write_string;
	close FILE;

	return 1;
}

=head2 write_string

  $test->write_string()

This method writes the test script as a chunk of text and returns it. Note
that this is the exact script written out to file via C<write>.

Code example:

  print "Test script:\n";
  print $test->write_string;

=cut

sub write_string {
	my $self    = shift;
	my $comment = $self->{comment} ? "\n# $self->{comment}" : '';
	my $modules = join "\n", map {
		"\t'$_ $self->{modules}->{$_}',"
	} sort keys %{$self->{modules}};
	my $o       = << "END_HEADER";
#!/usr/bin/perl
$comment
use strict;
BEGIN {
	\$|  = 1;
	\$^W = 1;
}

my \@MODULES = (
$modules
);

# Don't run tests during end-user installs
use Test::More;
END_HEADER

	# See if this is RELEASE_TESTING only
	$o .= "plan( skip_all => 'Author tests not required for installation' )\n";
	$o .= q|	unless ( $ENV{RELEASE_TESTING}|;
	unless ( $self->{release} ) {
		$o .= ' or $ENV{AUTOMATED_TESTING}';
	}
	$o .= " );\n\n";

	$o .= << 'END_MODULES';
# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

END_MODULES

	$o .= $self->{test} . "();\n\n";
	$o .= "1;\n";
	return $o;
}

1;

=pod

=head1 LIMITATIONS

This module is still missing support for lots of other author tests.

=head1 SUPPORT

This module is stored in an Open Repository at the following address:

L<http://svn.ali.as/cpan/trunk/Test-XT>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing) unit
tests, or can apply your fix directly instead of submitting a patch, you are
B<strongly> encouraged to do so. The author currently maintains over 100
modules and it may take some time to deal with non-critical bug reports or
patches.

This will guarantee that your issue will be addressed in the next release of
the module.

If you cannot provide a direct test or fix, or don't have time to do so, then
regular bug reports are still accepted and appreciated via the CPAN bug
tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-XT>

For other issues, for commercial enhancement and support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SEE ALSO

L<http://use.perl.org/~Alias/journal/38822>, which explains why this style
of testing is beneficial to you and the CPAN-at-large.

=head1 COPYRIGHT

Copyright 2009-2011 Adam Kennedy

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
