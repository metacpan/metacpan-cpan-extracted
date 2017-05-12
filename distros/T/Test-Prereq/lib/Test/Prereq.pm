package Test::Prereq;
use parent qw(Test::Builder::Module);

use strict;
use utf8;

use v5.22;
use feature qw(postderef);
no warnings qw(experimental::postderef);

use warnings;
no warnings;

=encoding utf8

=head1 NAME

Test::Prereq - check if Makefile.PL has the right pre-requisites

=head1 SYNOPSIS

	# if you use Makefile.PL
	use Test::More;
	eval "use Test::Prereq";
	plan skip_all => "Test::Prereq required to test dependencies" if $@;
	prereq_ok();

	# specify a perl version, test name, or module names to skip
	prereq_ok( $version, $name, \@skip );

	# if you use Module::Build
	use Test::More;
	eval "use Test::Prereq::Build";
	plan skip_all => "Test::Prereq::Build required to test dependencies" if $@;
	prereq_ok();

	# or from the command line for a one-off check
	perl -MTest::Prereq -eprereq_ok

    #The prerequisites test take quite some time so the following construct is
    #recommended for non-author testers
	use Test::More;
	eval "use Test::Prereq::Build";

	my $msg;
	if ($@) {
	    $msg = 'Test::Prereq::Build required to test dependencies';
	} elsif (not $ENV{TEST_AUTHOR}) {
	    $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
	}
	plan skip_all => $msg if $msg;
	prereq_ok();

=head1 DESCRIPTION

The C<prereq_ok()> function examines the modules it finds in
F<blib/lib/>, F<blib/script>, and the test files it finds in F<t/>
(and F<test.pl>). It figures out which modules they use and compares
that list of modules to those in the C<PREREQ_PM> section of
F<Makefile.PL>.

If you use C<Module::Build> instead, see L<Test::Prereq::Build>
instead.

=head2 Warning about redefining ExtUtils::MakeMaker::WriteMakefile

C<Test::Prereq> has its own version of
C<ExtUtils::MakeMaker::WriteMakefile> so it can run the F<Makefile.PL>
and get the argument list of that function.  You may see warnings
about this.

=cut

use vars qw($VERSION $EXCLUDE_CPANPLUS @EXPORT @prereqs);


$VERSION = '2.002';

@EXPORT = qw( prereq_ok );

use Carp qw(carp);
use ExtUtils::MakeMaker;
use File::Find;
use Module::Extract::Use;

my $Test = __PACKAGE__->builder;

{
no warnings;

* ExtUtils::MakeMaker::WriteMakefile = sub {
	my %hash = @_;

	my $name = $hash{NAME};
	my %prereqs =
		map { defined $_ ? %$_ : () }
		@hash{qw(PREREQ_PM BUILD_REQUIRES CONFIGURE_REQUIRES TEST_REQUIRES)};

	@Test::Prereq::prereqs = sort keys %prereqs;

	1;
	}
}

#unless( caller ) { prereq_ok() }

=head1 FUNCTIONS

=over 4

=item prereq_ok( [ VERSION, [ NAME [, SKIP_ARRAY] ] ] )

Tests F<Makefile.PL> to ensure all non-core module dependencies are in
C<PREREQ_PM>. If you haven't set a testing plan already,
C<prereq_ok()> creates a plan of one test.

If you don't specify a version, C<prereq_ok> assumes you want to compare
the list of prerequisite modules to the version of perl running the
test.

Valid versions come from C<Module::CoreList> (which uses C<$]>).

	#!/usr/bin/perl
	use Module::CoreList;
	print map "$_\n", sort keys %Module::CoreList::version;

C<prereq_ok> attempts to remove modules found in F<lib/> and
libraries found in F<t/> from the reported prerequisites.

The optional third argument is an array reference to a list
of names that C<prereq_ok> should ignore. You might want to use
this if your tests do funny things with C<require>.

Versions prior to 1.038 would use CPAN.pm to virtually include
prerequisites in distributions that you declared explicitly. This isn't
really a good idea. Some modules have moved to different distributions,
so you should just specify all the modules that you use instead of relying
on a particular distribution to provide them. Not only that, expanding
distributions with CPAN.pm takes forever.

If you want the old behavior, set the C<TEST_PREREQ_EXPAND_WITH_CPAN>
environment variable to a true value.

=cut

my $default_version = $];
my $version         = $];

sub prereq_ok {
	$Test->plan( tests => 1 ) unless $Test->has_plan;
	__PACKAGE__->_prereq_check( @_ );
	}

sub import {
    my $self   = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::prereq_ok'}       = \&prereq_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
	}

sub _prereq_check {
	my $class   = shift;

	my $name     = shift // 'Prereq test';
	my $skip     = shift // [];

	unless( ref $skip eq ref [] ) {
		carp( 'The second parameter to prereq_ok must be an array reference!' );
		return;
		}

	# get the declared prereqs from the Makefile.PL
	my $prereqs = $class->_get_prereqs();
	unless( $prereqs ) {
		$class->_not_ok( "\t" .
			$class->_master_file . " did not return a true value.\n" );
		return 0;
		}

	my $loaded  = $class->_get_loaded_modules();

	unless( $loaded ) {
		$class->_not_ok( "\tCouldn't look up the modules for some reasons.\n" ,
			"\tDo the blib/lib and t directories exist?\n",
			);
		return 0;
		}

	# remove modules found in PREREQ_PM
	foreach my $module ( @$prereqs ) {
		delete $loaded->{$module};
		}

	# remove modules found in distribution
	my $distro = $class->_get_dist_modules( 'blib/lib' );
	foreach my $module ( $distro->@* ) {
		delete $loaded->{$module};
		}

	# remove modules found in test directory
	$distro = $class->_get_test_libraries();
	foreach my $module ( $distro->@* ) {
		delete $loaded->{$module};
		}

	# remove modules in the skip array
	foreach my $module ( $skip->@* ) {
		delete $loaded->{$module};
		}

	if( $EXCLUDE_CPANPLUS ) {
		foreach my $module ( keys %$loaded ) {
			next unless $module =~ m/^CPANPLUS::/;
			delete $loaded->{$module};
			}
		}

	if( keys %$loaded ) { # stuff left in %loaded, oops!
		$class->_not_ok( "Found some modules that didn't show up in PREREQ_PM or *_REQUIRES\n",
			map { "\t$_\n" } sort keys %$loaded );
		}
	else {
		$Test->ok( 1, $name );
		}

	return 1;
	}

sub _not_ok {
	my( $self, $name, @message ) = @_;

	$Test->ok( 0, $name );
	$Test->diag( join "", @message );
	}

sub _master_file { 'Makefile.PL' }

sub _get_prereqs {
	my $class = shift;
	my $file = $class->_master_file;

	delete $INC{$file};  # make sure we load it again

	{
	local $^W = 0;

	unless( do "./$file" ) {
		print STDERR "_get_prereqs: Error loading $file: $@\n";
		return;
		}
	delete $INC{$file};  # pretend we were never here
	}

	my @modules = sort @Test::Prereq::prereqs;
	@Test::Prereq::prereqs = ();
	return \@modules;
	}

# get all the loaded modules.  we'll filter this later
sub _get_loaded_modules {
	my $class = shift;

#	return unless( defined $_[0] and defined $_[1] );
#	return unless( -d $_[0] and -d $_[1] );

	my( @libs, @t, @scripts );

	File::Find::find( sub { push @libs,    $File::Find::name if m/\.pm$/ }, 'blib/lib' )
		if -e 'blib/lib';
	File::Find::find( sub { push @t,       $File::Find::name if m/\.t$/  }, 't' )
		if -e 't';
	File::Find::find( sub { push @scripts, $File::Find::name if -f $_    }, 'blib/script' )
		if -e 'blib/script';

	my @found = ();
	foreach my $file ( @libs, @t, @scripts ) {
		push @found, @{ $class->_get_from_file( $file ) };
		}

	return { map { $_, 1 } @found };
	}

sub _get_test_libraries {
	my $class = shift;

	my $dirsep = "/";

	my @found = ();

	File::Find::find( sub { push @found, $File::Find::name if m/\.p(l|m)$/ }, 't' );

	my @files =
		map {
			my $x = $_;
			$x =~ s/^.*$dirsep//;
			$x =~ s|$dirsep|::|g;
			$x;
			}
			@found;

	push @files, 'test.pl' if -e 'test.pl';

	return \@files;
	}

sub _get_dist_modules {
	my $class = shift;

	return unless( defined $_[0] and -d $_[0] );

	my $dirsep = "/";

	my @found = ();

	File::Find::find( sub { push @found, $File::Find::name if m/\.pm$/ }, $_[0] );

	my @files =
		map {
			my $x = $_;
			$x =~ s/^$_[0]($dirsep)?//;
			$x =~ s/\.pm$//;
			$x =~ s|$dirsep|::|g;
			$x;
			}
			@found;

	return \@files;
	}

sub _get_from_file {
	state $extor = Module::Extract::Use->new;
	my( $class, $file ) = @_;

	my $modules  = $extor->get_modules_with_details( $file );

	# We also depend on the super classes, which might not be
	# part of the distro
	my @imports =
		map {
			state $can_import = { map { $_, 1 } qw(base parent) };
			exists $can_import->{$_->module}
				?
			$_->imports->@*
				:
				();
			} $modules->@*;

	my @modules = map { $_->module } $modules->@*;
	push @modules, @imports;

	return \@modules;
	}

=back

=head1 TO DO

=over 4

=item * set up a couple fake module distributions to test

=item * warn about things that show up in C<PREREQ_PM> unnecessarily

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/test-prereq

=head1 CONTRIBUTORS

Many thanks to:

Andy Lester, Slavin Rezić, Randal Schwartz, Iain Truskett, Dylan Martin

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT and LICENSE

Copyright © 2002-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.
This software is available under the Artistic License 2.

=cut

1;
