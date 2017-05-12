package Test::GreaterVersion;

=head1 NAME

Test::GreaterVersion -- Test if you incremented VERSION

=head1 SYNOPSIS

  has_greater_version('My::Module');

  has_greater_version_than_cpan('My::Module');
  
=head1 DESCRIPTION

There are two functions which are supposed to be used
in your automated release suites to assure that you incremented your
version before your install the module or upload it to CPAN.

C<has_greater_version> checks if your module source has a greater
VERSION number than the version installed in the system.

C<has_greater_version_than_cpan> checks if your module source has
a greater VERSION number than the version found on CPAN.

The version is checked by looking for the VERSION scalar in the
module. The names of these two functions are always exported.

The two test functions expect your module files layed out in
the standard way, i.e. tests are called in the top directory and
module if found in the C<lib> directory:

  Module Path
    doc
    examples
    lib
    t

The version of My::Module is therefore expected in the file
C<lib/My/Module.pm>. There's currently no way to alter that
location. (The file name is OS independent via the magic of
L<File::Spec>.)

The version information is actually parsed by
L<ExtUtils::MakeMaker>.

The version numbers are compared calling
C<CPAN::Version::vgt()>. See L<CPAN::Version> or L<version>
for version number syntax. (Short: Both 1.00203 and v1.2.30 work.)  

Please note that these test functions should not be put in normal
test script below C<t/>. They will usually break the tests.
These functions are to be put in some install script to check the
versions automatically.

=cut

use strict;
use warnings;

use ExtUtils::MakeMaker;
use CPAN;
use CPAN::Version;
use Cwd;
use File::Spec;
use Test::Builder;

use base qw(Exporter);
our @EXPORT = qw(has_greater_version
  has_greater_version_than_cpan);

our $VERSION = 0.010;

# the development version of the module is expected
# to be below this directory
our $libdir = 'lib';

our $Test = Test::Builder->new;

sub import {
	my ($self) = shift;
	my $pack = caller;

	$Test->exported_to($pack);
	$Test->plan(@_);

	$self->export_to_level( 1, $self, 'has_greater_version' );
	$self->export_to_level( 1, $self, 'has_greater_version_than_cpan' );
}

=head1 FUNCTIONS

=head2 has_greater_version ($module)

Returns 1 if your module in 'lib/' has a version and if
it is greater than the version of the installed module,
0 otherwise.

1 is also returned if the module is not installed, i.e. your
module is new.

1 is also returned if the module is installed but has no version
defined, i.e. your module in 'lib/' is a fix of this bug.

=cut

sub has_greater_version {
	my ($module) = @_;

	# fail if the module's name is missing
	unless ($module) {
		return $Test->diag("You didn't specify a module name");
	}

	my $version_from_lib = _get_version_from_lib($module);
	unless (defined $version_from_lib) {
		# fail if module is not in lib
		return $Test->diag('module is not in lib');
	}

	if ($version_from_lib eq 'undef') {
		# fail if module has no version
		return $Test->diag('module in lib has no version');
	}

	# so the module in lib has a version
	$Test->diag('module is in lib and has version');

	my $version_installed = _get_installed_version($module);
	unless (defined $version_installed) {
		$Test->diag('module is not installed');

		# module doesn't seem to be installed, that's okay --
		# it might be new
		return 1;
	}

 	if ($version_installed eq 'undef') {
		$Test->diag('version of installed module is not defined');

		# installed module seems to have no version, that's okay
		# if the module in lib has
		return 1;
 	}
 	
 	# so the installed module has a version, too
	$Test->diag('module is installed and has version');
 	# let's compare them
 	
	$Test->ok( CPAN::Version->vgt( $version_from_lib, $version_installed ),
		"$module has greater version" );
}

=head2 has_greater_version_than_cpan ($module)

Returns 1 if your module in 'lib/' has a version and if
it is greater than the module's version on CPAN,
0 otherwise.

1 is also returned if the module is there is no CPAN
information available for your module, i.e. your
module is new and will be the first release to CPAN or
has no version defined.

Due to the interface of the CPAN module there's currently
no way to tell if the module is not on CPAN or if there
has been an error in getting the module information from CPAN.
As a result this function should only be called if you are
sure that there's a version of the module on CPAN.

Depending on the configuration of your CPAN shell the first
call of this function may seem to block the test. When
you notice this behaviour it's likely that the CPAN shell is
trying to get the latest module index which may take some time.

Please note also that depending on your CPAN mirror the module
information might be up to date or not.

=cut

sub has_greater_version_than_cpan {
	my ($module) = @_;

	# fail if the module's name is missing
	unless ($module) {
		return $Test->diag('You didn\'t specify a module name');
	}

	my $version_from_lib = _get_version_from_lib($module);
	unless (defined $version_from_lib) {
		# fail if module is not in lib
		return $Test->diag('module is not in lib');
	}

	if ($version_from_lib eq 'undef') {
		# fail if module has no version
		return $Test->diag('module in lib has no version');
	}

	# so the module in lib has a version
	$Test->diag('module is in lib and has version');

	my $cpan_version = _get_version_from_cpan($module);
	unless ($cpan_version) {
		$Test->diag('module is not on CPAN or has no version');

		# module doesn't seem to be on CPAN, that's okay --
		# it might be new. If it has no version that's okay,
		# too -- we have one
		return 1;
	}
 	
 	# so the module on CPAN has a version, too
	$Test->diag('module is on CPAN and has version');
 	# let's compare them

	$Test->ok( CPAN::Version->vgt( $version_from_lib, $cpan_version ),
		"$module has greater version than on CPAN" );
}

=head1 INTERNAL FUNCTIONS

These are not to be called by anyone.

=head2 _get_installed_version ($module)

Gets the version of the installed module. The version
information is found with the help of the CPAN module.

Returns undef if the file doesn't exist.
Returns 'undef' (yes, the string) if it has no version.
Returns the version otherwise.

We don't use CPAN::Shell::inst_version() since it doesn't
remove blib before searching for the version and
we want to have a diag() output in the test. And because
the manpage doesn't list the function in the stable
interface.

=cut

sub _get_installed_version {
	my ($module) = @_;

	# Strip blib from @INC so the CPAN::Shell
	# won't find the module even if it's there.
	# (Tests add blib to @INC).
	# Localize @INC so we won't affect others
	local @INC = grep { $_ !~ /blib/ } @INC;

	my $file = _module_to_file($module);

	my $bestv;
	for my $incdir (@INC) {
		my $bfile = File::Spec->catfile( $incdir, $file );

		# skip if it's not a file
		next unless -f $bfile;

		# get the version
		my $foundv = MM->parse_version($bfile);

		# remember which version is greatest
		if ( !$bestv || CPAN::Version->vgt( $foundv, $bestv ) ) {
			$bestv = $foundv;
		}
	}

	return $bestv;
}

=head2 _get_version_from_lib ($module)

Gets the version of the module found in 'lib/'.
Transforms the module name into a filename which points
to a file found under 'lib/'.

C<MM->parse_version()> tries to find the version.

Returns undef if the file doesn't exist.
Returns 'undef' (yes, the string) if it has no version.
Returns the version otherwise.

=cut

sub _get_version_from_lib {
	my $module = shift;

	my $cwd  = getcwd();
	my $file =
	  File::Spec->catfile( $cwd, $libdir, _module_to_file($module));    

	unless (-f $file) {
		$Test->diag("file '$file' doesn't exist");
		return;
	}
	
	# try to get the version
	my $code = sub { MM->parse_version($file) };
	my ( $version, $error ) = $Test->_try($code);

	# fail on errors
	return $Test->diag("parse_version had errors: $@")
	  if $error;

	return $version;

}

# convert module name to file under lib (OS-independent)
sub _module_to_file {
	my ($module) = @_;

	# get list of components
	my @components = split( /::/, $module );

	# a/b.pm under UNI* for 'a::b'
	my $file=File::Spec->catfile(@components);

	return "$file.pm";
}

=head2 _get_version_from_cpan ($module)

Gets the module's version as found on CPAN. The version
information is found with the help of the CPAN module.

Returns undef if the module is not on CPAN or the CPAN module
failed somehow. Returns the version otherwise.

=cut

sub _get_version_from_cpan {
	my ($module) = @_;

	# Turn off coloured output of the CPAN shell.
	# This breaks the test/Harness/whatever.
	CPAN::HandleConfig->load();
	$CPAN::Config->{colorize_output} = 0;

	# taken from CPAN manpage
	my $m = CPAN::Shell->expand( 'Module', $module );

	# the module is not on CPAN or something broke
	unless ($m) {
		$Test->diag("CPAN-version of '$module' not available");
		return;
	}

	# there is a version on CPAN
	return $m->cpan_version();
}

=head1 NOTES

This module was inspired by brian d foy's talk
'Managing Complexity with Module::Release' at the Nordic Perl
Workshop in 2006.

=head1 TODO

It might be nice that has_greater_version() and
has_greater_version_than_cpan() wouldn't fail on equal versions
if the modules source code is equal, too. Thanks to Slaven Rezic
for that suggestion. That way the tests could be used in a normal
test suite.


=head1 AUTHOR

Gregor Goldbach <ggoldbach@cpan.org>

=head1 SIMILAR MODULES

L<Test::Version> tests if there is a VERSION defined.

L<Test::HasVersion> does it, too, but has the ability to
check all Perl modules in C<lib>.

Neither of these compare versions.

=head1 COPYRIGHT

Copyright (c) 2007 by Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
