package Test::Distribution;

# pragmata
use strict;
use vars qw($VERSION @default_types @supported_types);
use warnings;

# perl modules
use ExtUtils::Manifest qw(manicheck);
use Test::More;


$VERSION = '2.00';

@default_types = qw/manifest use versions prereq pod description podcover/;
@supported_types = qw/manifest use versions prereq pod description podcover sig/;

my @error;
for (qw/File::Spec File::Basename File::Find::Rule/) {
	eval "require $_";
	push @error => $_ if $@;
}
if (@error) {
	# construct a nice message with proper placement of commas and
	# the verb 'to be' in the enumeration of the error(s)

	@error = sort @error;
	my $is = @error == 1 ? 'is' : 'are';
	my $last = pop @error;
	my $msg = join ', ' => @error;
	$msg .= ' and ' if length $msg;
	$msg .= "$last $is required for Test::Distribution";
	plan skip_all => $msg;
	exit;
}

# This runs during BEGIN

sub import {
	return if our $been_here++;
	my $pkg = shift;
	my %args = @_;

	use vars qw(@default_types);
	$args{only} ||= \@default_types;
	$args{only} = [ $args{only} ] unless ref $args{only} eq 'ARRAY';

	$args{not} ||= [];
	$args{not} = [ $args{not} ] unless ref $args{not} eq 'ARRAY';

	$args{tests} ||= 0;

	$args{dirlist} = [ qw(blib lib) ];
	$args{dir}   ||= File::Spec->catfile(@{ $args{dirlist} });

	$args{podcoveropts} ||= {};

	run_tests(\%args);
}

# This runs after CHECK, i.e. at run-time

sub run_tests {
	my $args = shift;
	my %args = %$args;

	our @files = -d $args{dir} ? File::Find::Rule->file()->name('*.pm')->in($args{dir}) : ();

	our @packages = map {
	    # $_ is like 'blib/lib/Foo/Bar/Baz.pm',
	    # after splitpath: $dir is 'blib/lib/Foo/Bar', $file is 'Baz.pm',
	    # after splitdir: @dir is qw(blib lib Foo Bar),
	    # after shifting off @{$args{dirlist}}, @dir is qw(Foo Bar),
	    # so now we can portably construct the package name.

	    my ($vol, $dir, $file) = File::Spec->splitpath($_);
	    my @dir = grep { length } File::Spec->splitdir($dir);
	    shift @dir for @{ $args{dirlist} };
	    join '::' => @dir, File::Basename::basename($file, '.pm');
	    } @files;

	my %perform;
	%perform = map { $_ => 1 } @{$args{only}};
	delete @perform{ @{$args{not}} };

	# need to use() modules before we can check their $VERSIONS,
	# so we might as well test with use_ok().

	$perform{use} = 1 if $perform{versions};

	our %testers;
	our $tests = $args{tests};
	for my $type (keys %perform) {
		die "no such test type: $type\n"
		    unless grep /^$type$/ => our @supported_types;

		my $pkg = __PACKAGE__ . '::' . $type;
		$testers{$type} = $pkg->new(
		    packages => \@packages,
		    files    => \@files,
		    %args,
		);

		$tests += $testers{$type}->num_tests;
	}

	plan tests => $tests;

	for my $type (@supported_types) {
		$testers{$type}->run_tests($args) if $perform{$type};
	}
}

sub packages  { our @packages }
sub files     { our @files }
sub num_tests { our $tests }

package Test::Distribution::base;

sub new {
	my ($class, %args) = @_;
	bless \%args, $class;
}

sub num_tests { 0 }
sub run_tests {}


package Test::Distribution::pod;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { scalar @{ $_[0]->{files} } }

sub run_tests { SKIP: {
	my $self = shift;

	eval {
		require Test::Pod;
		Test::Pod->import;
	};
	skip 'Test::Pod required for testing POD', $self->num_tests() if $@;

	for my $file (@{ $self->{files} }) { pod_file_ok($file) }
} }


package Test::Distribution::podcover;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { scalar @{ $_[0]->{packages} } }

sub run_tests { SKIP: {
	my $self = shift;
	my $args = shift;

	eval {
		require Test::Pod::Coverage;
		Test::Pod::Coverage->import;
	};
	skip 'Test::Pod::Coverage required for testing POD', $self->num_tests() if $@;

	my $trustme = $args->{podcoveropts};
	for my $package (@{ $self->{packages} }) { pod_coverage_ok($package, $trustme, 'Pod Coverage ok') }
} }


package Test::Distribution::use;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { scalar @{ $_[0]->{packages} } }

sub run_tests {
	my $self = shift;
	for my $package (@{ $self->{packages} }) { use_ok($package) }
}


package Test::Distribution::versions;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { 
   my $self = shift;
   
   my $num_packages = scalar @{ $self->{packages} };

   if($self->{distversion}) {
       return $num_packages * 2 - 1;  # Don't test package itself to see if its own dist version matches
   }
   else {
       return $num_packages;
   }

}

sub run_tests {
	my $self = shift;

	for my $package (@{ $self->{packages} }) {
	    our $version;
	    
	    my $this_version = do {
		no strict 'refs';
	     	${"$package\::VERSION"}
    	    };

	    unless (defined $version) {
		$version = $this_version;
		ok(defined($version), "$package defines a version");
		next;
	    }

    	    ok(defined($version), "$package defines a version");

	    if($self->{distversion}) {
		is($this_version, $version, "$package version matches");
	    }
	}
}


package Test::Distribution::description;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { 4 }

sub run_tests {
	my $self = shift;
	ok(-e, "$_ exists") for qw/MANIFEST README/;
  ok(-e 'Changes' || -e 'ChangeLog' || -e 'Changes.pod' || -e 'ChangeLog.pod', 'Changes(.pod)? or ChangeLog(.pod)? exists');
	ok(-e 'Build.PL' || -e 'Makefile.PL', 'Build.PL or Makefile.PL exists');
}


package Test::Distribution::manifest;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { 1 }

sub run_tests {
    my $self = shift;
   
    my @missing_files = ExtUtils::Manifest::manicheck();
    ok(scalar @missing_files == 0, "Checking MANIFEST integrity");
}


package Test::Distribution::prereq;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { 1 }

sub run_tests { SKIP: {
	my $self = shift;

	eval {
		require File::Find::Rule;
		require Module::CoreList;
	};
	skip 'Module::Build PREREQ_PM not yet implemented', $self->num_tests() if -f 'Build.PL';
	skip 'File::Find::Rule and Module::CoreList required for testing PREREQ_PM', $self->num_tests() if $@;
	skip "testing PREREQ_PM not implemented for perl $] because Module::CoreList doesn't know about it", $self->num_tests unless
        exists $Module::CoreList::version{ $] };

	my (%use, %package);

	File::Find::Rule->file()->nonempty()->or(
	    File::Find::Rule->name(qr/\.p(l|m|od)$/),
	    File::Find::Rule->exec(sub {
		my $fh;
		return 0 unless open $fh, $_;
		my $shebang = <$fh>;
		close $fh;
		return $shebang =~ /^#!.*\bperl/;
	    }),
	)->exec(sub {
	    my $fh;
	    return 0 unless open $fh, $_;
	    while (<$fh>) {
		    $use{$1}++ if /^use \s+ ([^\W\d][\w:]+) (\s*\n | .*;)/x;
		    $package{$1}++ if /^package \s+ ([\w:]+) \s* ;/x;
	    }
	    return 1;
	})->in($self->{dir});

	# We're not interested in use()d modules that are provided by
	# this distro, or in core modules. It's ok core modules aren't
	# mentioned in PREREQ_PM.

	no warnings 'once';
	delete @use{ keys %package, keys %{ $Module::CoreList::version{$]} } };

	open my $fh, 'Makefile.PL' or die "can't open Makefile.PL: $!\n";
	my $make = do { local $/; <$fh> };
	close $fh or die "can't close Makefile.PL: $!\n";
	$make =~ s/use \s+ ExtUtils::MakeMaker \s* ;/no strict;/gx;

	$make .= 'sub WriteMakefile {
	    my %h = @_; our @prereq = keys %{ $h{PREREQ_PM} || {} } }';
	eval $make;
	die $@ if $@;

	delete @use{our @prereq};
	ok(keys(%use) == 0, 'All non-core use()d modules listed in PREREQ_PM')
	  or diag(prereq_error(%use));
} }

# construct an error message for test output
sub prereq_error {
    my %use = @_;
    my @modules = sort keys %use;
    (@modules > 1 ? 'These modules are' : 'A module is') .
      " used but not mentioned in Makefile.PL's PREREQ_PM:\n" .
      join "\n" => map { "  $_" } @modules;
}

# XXX - not yet implemented and no docs or tests yet.
package Test::Distribution::exports;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests { 0 }

sub run_tests {
	my $self = shift;
}

package Test::Distribution::sig;
use Test::More;
our @ISA = 'Test::Distribution::base';

sub num_tests {
	return (-f 'SIGNATURE') ? 1 : 0;
}

sub run_tests { SKIP: {
	my $self = shift;
	return unless $self->num_tests();
	eval {
		require Module::Signature;
		Module::Signature->import;
	};
	if($@) {
		skip 'Module::Signature required for this test', $self->num_tests();
	}
	else {
		my $ret = Module::Signature::verify();
    skip "Module::Signature cannot verify", 1 if $ret eq Module::Signature::CANNOT_VERIFY();

    cmp_ok $ret, '==', Module::Signature::SIGNATURE_OK(), "Valid signature";
	}
} }
1;

__END__

=head1 NAME

Test::Distribution - perform tests on all modules of a distribution

=head1 SYNOPSIS

  $ cat t/01distribution.t
  use Test::More;

  BEGIN {
	eval {
		require Test::Distribution;
	};
	if($@) {
		plan skip_all => 'Test::Distribution not installed';
	}
	else {
		import Test::Distribution;
	}
   }

  $ make test
  ...

=head1 DESCRIPTION

When using this module in a test script, it goes through all the modules
in your distribution, checks their POD, checks that they compile ok and
checks that they all define a  $VERSION.

This module also performs a numer of test on  the distribution itself. It
checks that your files match your  SIGNATURE file if you  have one. It checks
that your distribution  isn't missing certain 'core'  description files.  It
checks to see you havent' missed out listing any pre-requisites in Makefile.PL.

It defines its own testing plan, so you usually don't use it in
conjunction with other C<Test::*> modules in the same file. It's
recommended that you just create a one-line test script as shown in the
SYNOPSIS above. However, there are options...

B<NOTE> If you do not specify any options Test::Distribution will run all test
types B<except> signature testing which must always be explicitly switched on.

In the future I may change the default to run no tests at all as this sounds
safer. Mail me if you disagree.

=head1 OPTIONS

On the line in which you C<use()> this module, you can specify named
arguments that influence the testing behavior.

=over 4

=item C<tests =E<gt> NUMBER>

Specifies that in addition to the tests run by this module, your test
script will run additional tests. In other words, this value influences
the test plan. For example:

  use Test::Distribution tests => 1;
  use Test::More;
  is($foo, $bar, 'baz');

It is important that you don't specify a C<tests> argument when
using C<Test::More> or other test modules as the plan is handled by
C<Test::Distribution>.

DEPRECATED FEATURE. I plan to remove this in the future unless I'm contacted by
someone that says they find this useful.

=item C<only =E<gt> STRING|LIST>

Specifies that only certain sets of tests are to be run. Possible values
are those mentioned in TEST TYPES below. For example, if you only want
to run the POD tests, you could say:

  use Test::Distribution only => 'pod';

To specify that you only want to run the POD tests and the C<use> tests,
and also that you are going to run two tests of your own, use:

  use Test::Distribution
    only  => [ qw/pod use/ ],
    tests => 2;

Note that when you specify the C<versions> option, the C<use> option
is automatically added. This is because in order to get a module's
C<$VERSION>, it has to be loaded. In this case we might as well run a
C<use> test.

The value for C<only> can be a string or a reference to a list of strings.

=item C<not =E<gt> STRING|LIST>

Specifies that certain types of tests should not be run. All tests not
mentioned in this argument are run. For example, if you want to test
everything except the POD, use:

  use Test::Distribution
    not => 'pod';

The value for C<not> can be a string or a reference to a list of
strings. Although it doesn't seem to make much sense, you can use both
C<only> and C<not>. In this case only the tests specified in C<only>,
but not C<not> are run (if this makes any sense).

=item C<distversion>

If you test this to a true value, as well as testing that each module has a
$VERSION defined, Test::Distribution will also ensure that the $VERSION matches
that of the distribution.

=item C<podcoveropts>

You can set this to be a hash reference of options to pass to
Test::Pod::Coverage's pod_coverage_ok method (which in turn gets passed to
Pod::Coverage.

=back

=head1 TEST TYPES

Here is a description of the types of tests available.

=over 4

=item C<description>

Checks that the following files exist:

=over 4

=item Changes  or ChangeLog

=item MANIFEST

=item README

=item Build.PL or Makefile.PL

=back

=item C<prereq>

Checks whether all C<use()>d modules that aren't in the perl core are
also mentioned in Makefile.PL's C<PREREQ_PM>.

=item C<pod>

Checks for POD errors in files

=item C<podcover>

Checks for Pod Coverage

=item C<sig>

If the distribution   has a SIGNATURE  file, checks  the  SIGNATURE matches  the
files.

=item C<use>

This C<use()>s the modules to make sure the load happens ok.

=item C<versions>

Checks that all packages define C<$VERSION> strings.

=back

=head1 EXPOSED INTERNALS

There are a few subroutines to help you see what this module is
doing. Note that these subroutines are neither exported nor exportable,
so you have to call them fully qualified.

=over 4

=item C<Test::Distribution::packages()>

This is a list of packages that have been found. That is, we assume that
each file contains a package of the name indicated by the file's relative
position. For example, a file in C<blib/lib/Foo/Bar.pm> is expected to
be available via C<use Foo::Bar>.

=item C<Test::Distribution::files()>

This is a list of files that tests have been run on. The filenames
are relative to the distribution's root directory, so they start with
C<blib/lib>.

=item C<Test::Distribution::num_tests()>

This is the number of tests that this module has run, based on your
specifications.

=back

=head1 INSTALLATION

This module uses Module::Build for its installation. To install this module type
the following:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install


If you do not have Module::Build type:

  perl Makefile.PL

to fetch it. Or use CPAN or CPANPLUS and fetch it "manually".

=head1 DEPENDENCIES

This module requires these other modules and libraries:

 File::Basename
 File::Find::Rule
 File::Spec
 Test::More

This module has these optional dependencies:

 Module::CoreList
 Test::Pod
 Test::Pod::Coverage

If C<Module::CoreList> is missing, the C<prereq> tests are skipped.

If C<Test::Pod> is missing, the C<pod> tests are skipped.

=head1 TODO

Just because these items are in the todo list,  does not mean they will actually
be done. If you  think one of these  would be helpful say  so - and it will then
move up on my priority list.

=over 4

=item *

Module::Build support  [currently waiting for a fix on Test::Prereq ]

=back

=head1 FEATURE IDEAS

=over 4

=item C<export> test type

This would mandate that there should be a test for each exported symbol
of each module.

=back

Let me know what you think of these ideas. Are they
necessary? Unnecessary? Do you have feature requests of your own?

=head1 BUGS

To report a bug  or request an enhancement use CPAN's  excellent Request
Tracker. 

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in svn.

http://sourceforge.net/projects/sagar-r-shah/

=head1 AUTHORS

Marcel GrE<uuml>nauer <marcel@cpan.org>

Sagar R. Shah

=head1 OTHER CREDITS

This module was inspired by a use.perl.org journal  entry by C<brian d foy> (see
L<http://use.perl.org/~brian_d_foy/journal/7463>) where he  describes an idea by
Andy Lester.

=head1 COPYRIGHT & LICENSE

Copyright 2002-2003 Marcel GrE<uuml>nauer. All rights reserved.

Copyright 2003-2007, Sagar R. Shah, All rights reserved.

This program  is free software; you can  redistribute it  and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

perl(1),   ExtUtils::Manifest(3pm),  File::Find::Rule(3pm),
Module::CoreList(3pm),       Test::More(3pm),      Test::Pod(3pm),
Test::Pod::Coverage(3pm), Test::Signature(3pm).

=cut

