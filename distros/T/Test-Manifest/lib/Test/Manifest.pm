package Test::Manifest;
use strict;

use warnings;
no warnings;

use Exporter qw(import);

use Carp qw(carp);
use File::Spec::Functions qw(catfile);

our @EXPORT    = qw(run_t_manifest);
our @EXPORT_OK = qw(get_t_files make_test_manifest manifest_name);

our $VERSION = '2.024';

my %SeenInclude = ();
my %SeenTest = ();

require 5.008;

sub MY::test_via_harness {
	my($self, $perl, $tests) = @_;

	return qq|\t$perl "-MTest::Manifest" | .
		   qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
		   qq|'\$(INST_ARCHLIB)', \$(TEST_LEVEL) )"\n|;
	};

=encoding utf8

=head1 NAME

Test::Manifest - interact with a t/test_manifest file

=head1 SYNOPSIS

	# in Makefile.PL
	eval "use Test::Manifest 2.00";

	# in Build.PL
	my $class = do {
		if( eval 'use Test::Manifest 2.00; 1' ) {
			Test::Manifest->get_module_build_subclass;
			}
		else {
			'Module::Build';
			}
		};

	my $build = $class->new( ... )

	# in the file t/test_manifest, list the tests you want
	# to run in the order you want to run them

=head1 DESCRIPTION

C<Test::Harness> assumes that you want to run all of the F<.t> files
in the F<t/> directory in ASCII-betical order during C<make test> or
C<./Build test> unless you say otherwise.  This leads to some
interesting naming schemes for test files to get them in the desired
order. These interesting names ossify when they get into source
control, and get even more interesting as more tests show up.

C<Test::Manifest> overrides the default test file order. Instead of
running all of the F<t/*.t> files in ASCII-betical order, it looks in
the F<t/test_manifest> file to find out which tests you want to run
and the order in which you want to run them.  It constructs the right
value for the build system to do the right thing.

In F<t/test_manifest>, simply list the tests that you want to run.
Their order in the file is the order in which they run.  You can
comment lines with a C<#>, just like in Perl, and C<Test::Manifest>
will strip leading and trailing whitespace from each line.  It also
checks that the specified file is actually in the F<t/> directory.  If
the file does not exist, it does not put its name in the list of test
files to run and it will issue a warning.

Optionally, you can add a number after the test name in test_manifest
to define sets of tests. See C<get_t_files> for more information.

=head2 ExtUtils::MakeMaker

To override the test order behaviour in C<MakeMaker>, C<Test::Manifest>
inserts itself in the C<test_via_harness> step by providing its own
test runner. In C<Makefile.PL>, all you have to do is load C<Test::Manifest>
before you call C<WriteMakefile>. To make it optional, load it in an eval:

	eval "use Test::Manifest";

=head2 Module::Build

Overriding parts of C<Module::Build> is tricker if you want to use the
subclassing mechanism and still make C<Test::Manifest> optional. If you
can load C<Test::Manifest> (version 2.00 or later), C<Test::Manifest> can
create the subclass for you.

	my $class = do {
		if( eval 'use Test::Manifest 2.00; 1' ) {
			Test::Manifest->get_module_build_subclass;
			}
		else {
			'Module::Build' # if Test::Manifest isn't there
			}
		};

	$class->new( ... );
	$class->create_build_file;

This is a bit of a problem when you already have your own subclass.
C<Test::Manifest> overrides C<find_test_files>, so you can get just
that code to add to your own subclass code string:

	my $code = eval 'use Test::Manifest 2.00; 1'
			?
		Test::Manifest->get_module_build_code_string
			:
		'';

	my $class = Module::Build->subclass(
		...,
		code => "$code\n...your subclass code string...",
		);

=head2 Class methods

=over 4

=item get_module_build_subclass

For C<Module::Build> only.

Returns a C<Module::Build> subclass that overrides C<find_test_files>. If
you want to have your own C<Module::Build> subclass and still use
C<Test::Manifest>, you can get just the code string with
C<get_module_build_code_string>.

=cut

sub get_module_build_subclass {
	my( $class ) = @_;


	require Module::Build;

	my $class = Module::Build->subclass(
     	class => 'Test::Manifest::MB',

		code  => $class->get_module_build_code_string,
    	);

	$class->log_info( "Using Test::Manifest $VERSION\n" );

	$class;
	}

=item get_module_build_code_string

For C<Module::Build> only.

Returns the overridden C<find_test_files> as Perl code in a string suitable
for the C<code> key in C<Module::Build->subclass()>. You can add this to other
bits you are overriding or extending.

See C<Module::Build::Base::find_test_files> to see the base implementation.

=cut

sub get_module_build_code_string {
	 q{
	 sub find_test_files {
	 	my $self = shift;
	 	my $p = $self->{properties};

	 	my( $level ) = grep { defined } (
	 		$ENV{TEST_LEVEL},
	 		$p->{ 'testlevel' },
	 		0
	 		);

	 	$self->log_verbose( "Test level is $level\n" );

		require Test::Manifest;
		my @files = Test::Manifest::get_t_files( $level );
		\@files;
		}
	}
	}

=back

=head2 Functions

=over 4

=item run_t_manifest( TEST_VERBOSE, INST_LIB, INST_ARCHLIB, TEST_LEVEL )

For C<MakeMaker> only. You don't have to mess with this at the user
level.

Run all of the files in F<t/test_manifest> through C<Test::Harness:runtests>
in the order they appear in the file. This is inserted automatically

	eval "use Test::Manifest";

=cut

sub run_t_manifest {
	require Test::Harness;
	require File::Spec;

	$Test::Harness::verbose = shift;

	local @INC = @INC;
	unshift @INC, map { File::Spec->rel2abs($_) } @_[0,1];

	my( $level ) = $_[2] || 0;

	print STDERR "Test::Manifest $VERSION\n"
		if $Test::Harness::verbose;

	print STDERR "Level is $level\n"
		if $Test::Harness::verbose;

	my @files = get_t_files( $level );
	print STDERR "Test::Manifest::test_harness found [@files]\n"
		if $Test::Harness::verbose;

	Test::Harness::runtests( @files );
	}

=item get_t_files( [LEVEL] )

In scalar context it returns a single string that you can use directly
in C<WriteMakefile()>. In list context it returns a list of the files it
found in F<t/test_manifest>.

If a F<t/test_manifest> file does not exist, C<get_t_files()> returns
nothing.

C<get_t_files()> warns you if it can't find F<t/test_manifest>, or if
entries start with F<t/>. It skips blank lines, and strips Perl
style comments from the file.

Each line in F<t/test_manifest> can have three parts: the test name,
the test level (a floating point number), and a comment. By default,
the test level is 1.

	test_name.t 2  #Run this only for level 2 testing

Without an argument, C<get_t_files()> returns all the test files it
finds. With an argument that is true (so you can't use 0 as a level)
and is a number, it skips tests with a level greater than that
argument. You can then define sets of tests and choose a set to
run. For instance, you might create a set for end users, but also
add on a set for deeper testing for developers.

Experimentally, you can include a command to grab test names from
another file. The command starts with a C<;> to distinguish it
from a true filename. The filename (currently) is relative to the
current working directory, unlike the filenames, which are relative
to C<t/>. The filenames in the included are still relative to C<t/>.

	;include t/file_with_other_test_names.txt

Also experimentally, you can stop C<Test::Manifest> from reading
filenames with the C<;skip> directive. C<Test::Manifest> will skip the
filenames up to the C<;unskip> directive (or end of file):

	run_this1
	;skip
	skip_this
	;unskip
	run_this2

To select sets of tests, specify the level in the environment variable
C<TEST_LEVEL>:

	make test # run all tests no matter the level
	make test TEST_LEVEL=2  # run all tests level 2 and below

Eventually this will end up as an option to F<Build.PL>:

	./Build test --testlevel=2  # Not yet supported

=cut

sub get_t_files {
	my $upper_bound = shift;
	print STDERR "# Test level is $upper_bound\n"
		if $Test::Harness::verbose;

	%SeenInclude = ();
	%SeenTest    = ();

	my $Manifest = manifest_name();
	carp( "$Manifest does not exist!" ) unless -e $Manifest;
	my $result = _load_test_manifest( $Manifest, $upper_bound );
	return unless defined $result;
	my @tests = @{$result};

	return wantarray ? @tests : join " ", @tests;
	}

# Wrapper for loading test manifest files to support including other files
sub _load_test_manifest {
	my $manifest = shift;
	return unless open my( $fh ), '<', $manifest;

	my $upper_bound = shift || 0;
	my @tests = ();

	LINE: while( <$fh> ) {
		s/#.*//; s/^\s+//; s/\s+$//;

		next unless $_;

		my( $command, $arg ) = split /\s+/, $_, 2;
		if( ';' eq substr( $command, 0, 1 ) ) {
			if( $command eq ';include' ) {
				my $result = _include_file( $arg, $., $upper_bound );
				push @tests, @$result if defined $result;
				next;
				}
			elsif( $command eq ';skip' ) {
				while( <$fh> ) { last if m/^;unskip/ }
				next LINE;
				}
			else {
				croak( "Unknown directive: $command" );
				}
			}

		my( $test, $level ) = ( $command, $arg );
		$level = 1 unless defined $level;

		next if( $upper_bound and $level > $upper_bound );

		carp( "Bad value for test [$test] level [$level]\n".
			"Level should be a floating-point number\n" )
			unless $level =~ m/^\d+(?:.\d+)?$/;
		carp( "test file begins with t/ [$test]" ) if m|^t/|;

		if( -e catfile( "t", $test ) ) {
			$test = catfile( "t", $test )
			}
		else {
			carp( "test file [$test] does not exist! Skipping!" );
			next;
			}

		# Make sure we don't include a test we've already seen
		next if exists $SeenTest{$test};

		$SeenTest{$test} = 1;
		push @tests, $test;
		}

	close $fh;
	return \@tests;
	}

sub _include_file {
	my( $file, $line, $upper_bound ) = @_;
	print STDERR "# Including file $file at line $line\n"
		if $Test::Harness::verbose;

	unless( -e $file ) {
		carp( "$file does not exist" ) ;
		return;
		}

	if( exists $SeenInclude{$file} ) {
		carp( "$file already loaded - skipping" ) ;
		return;
		}

	$SeenInclude{$file} = $line;

	my $result = _load_test_manifest( $file, $upper_bound );
	return unless defined $result;

	$result;
	}


=item make_test_manifest()

Creates the test_manifest file in the t directory by reading the
contents of the F<t/> directory.

TO DO: specify tests in argument lists.

TO DO: specify files to skip.

=cut

sub make_test_manifest() {
	carp( "t/ directory does not exist!" ) unless -d "t";
	return unless open my( $fh ), '>',  manifest_name();

	my $count = 0;
	while( my $file = glob("t/*.t") ) {
		$file =~ s|^t/||;
		print $fh "$file\n";
		$count++;
		}
	close $fh;

	return $count;
	}

=item manifest_name()

Returns the name of the test manifest file, relative to F<t/>.

=cut

{
my $Manifest = catfile( "t", "test_manifest" );

sub manifest_name {
	return $Manifest;
	}
}

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/test-manifest/

=head1 CREDITS

Matt Vanderpol suggested and supplied a patch for the C<;include>
feature.

Olivier Mengué supplied a documentation patch.

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut


1;
