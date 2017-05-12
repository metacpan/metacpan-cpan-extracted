package Test::Dist::VersionSync;

use strict;
use warnings;

use Data::Dumper;
use Test::More;


=head1 NAME

Test::Dist::VersionSync - Verify that all the modules in a distribution have the same version number.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 SYNOPSIS

	use Test::Dist::VersionSync;
	Test::Dist::VersionSync::ok_versions();


=head1 USE AS A TEST FILE

The most common use should be to add a module_versions.t file to your tests directory for a given distribution, with the following content:

	#!perl -T

	use strict;
	use warnings;

	use Test::More;

	# Ensure a recent version of Test::Dist::VersionSync
	my $version_min = '1.0.1';
	eval "use Test::Dist::VersionSync $version_min";
	plan( skip_all => "Test::Dist::VersionSync $version_min required for testing module versions in the distribution." )
		if $@;

	Test::Dist::VersionSync::ok_versions();

=head1 FUNCTIONS

=head2 ok_versions()

Verify that all the Perl modules in the distribution have the same version
number.

	# Default, use MANIFEST and MANIFEST.SKIP to find out what modules exist.
	ok_versions();

	# Optional, specify a list of modules to check for identical versions.
	ok_versions(
		modules =>
		[
			'Test::Module1',
			'Test::Module2',
			'Test::Module3',
		],
	);

=cut

sub ok_versions
{
	my ( %args ) = @_;
	my $modules = delete( $args{'modules'} );
	my $return = 1;

	# Find out via Test::Builder if a plan has been declared, otherwise we'll
	# declare our own.
	my $builder = Test::More->builder();
	my $plan_declared = $builder->has_plan();

	# If a list of files was passed, verify that the argument is an arrayref.
	# Otherwise, load the files from MANIFEST and MANIFEST.SKIP.
	if ( defined( $modules) )
	{
		Test::More::plan( tests => 3 )
			unless $plan_declared;

		$return = Test::More::isa_ok(
			$modules,
			'ARRAY',
			'modules list',
		) && $return;
	}
	else
	{
		Test::More::plan( tests => 5 )
			unless $plan_declared;

		$modules = _get_modules_from_manifest();
	}

	# If we have modules, check their versions.
	SKIP:
	{
		Test::More::skip(
			'No module found in the distribution.',
			2,
		) if scalar( @$modules ) == 0;

		my $versions = {};
		$return = Test::More::subtest(
			'Retrieve versions for all modules listed.',
			sub
			{
				Test::More::plan( tests => scalar( @$modules ) * 2 );

				foreach my $module ( @$modules )
				{
					Test::More::use_ok( $module );

					my $version = $module->VERSION();
					my $version_declared = Test::More::ok(
						defined( $version ),
						"Module $module declares a version.",
					);

					$version = '(undef)'
						unless $version_declared;

					$versions->{ $version } ||= [];
					push( @{ $versions->{ $version } }, $module );
				}
			}
		) && $return;

		my $has_only_one_version = is(
			scalar( keys %$versions ),
			1,
			'The modules declare only one version.',
		);
		diag( 'Versions and the modules they were found in: ' . Dumper( $versions ) )
			unless $has_only_one_version;
		$return = $has_only_one_version && $has_only_one_version;

	}

	return $return;
}


=head2 import()

Import a test plan. This uses the regular Test::More plan options.

	use Test::Dist::VersionSync tests => 4;

	ok_versions();

Test::Dist::VersionSync also detects if Test::More was already used with a test
plan declared and will piggyback on it. For example:

	use Test::More tests => 2;
	use Test::Dist::VersionSync;

	ok( 1, 'Some Test' );
	ok_versions();

=cut

sub import
{
	my ( $self, %test_plan ) = @_;

	Test::More::plan( %test_plan )
		if scalar( keys %test_plan ) != 0;

	return 1;
}


=begin _private

=head1 INTERNAL FUNCTIONS

=head2 _get_modules_from_manifest

Retrieve an arrayref of modules using the MANIFEST file at the root of the
distribution. IF MANIFEST.SKIP is present, its list of exclusions is used
to filter out modules to verify.

	my $modules = _get_modules_from_manifest();

=end _private

=cut

sub _get_modules_from_manifest
{
	# Gather a list of exclusion patterns for files listed in MANIFEST.
	my $excluded_patterns;
	if ( -e 'MANIFEST.SKIP' )
	{
		my $opened_manifest_skip = Test::More::ok(
			open( my $MANIFESTSKIP, '<', 'MANIFEST.SKIP' ),
			'Retrieve MANIFEST.SKIP file.',
		) || diag( "Failed to open < MANIFEST.SKIP file: $!." );

		if ( $opened_manifest_skip )
		{
			my $exclusions = [];
			while ( my $pattern = <$MANIFESTSKIP> )
			{
				chomp( $pattern );
				push( @$exclusions, $pattern );
			}
			close( $MANIFESTSKIP );

			$excluded_patterns = '(' . join( '|', @$exclusions ) . ')'
				if scalar( @$exclusions ) != 0;
		}
	}
	else
	{
		Test::More::ok(
			1,
			'No MANIFEST.SKIP found, skipping.',
		);
	}

	# Make sure that there is a MANIFEST file at the root of the distribution,
	# before we even open it.
	my $manifest_exists = Test::More::ok(
		-e 'MANIFEST',
		'The MANIFEST file is present at the root of the distribution.',
	);

	# Retrieve the list of modules in MANIFEST.
	my $modules = [];
	SKIP:
	{
		Test::More::skip(
			'MANIFEST is missing, cannot retrieve list of files.',
			1,
		) unless $manifest_exists;

		my $opened_manifest = Test::More::ok(
			open( my $MANIFEST, '<', 'MANIFEST' ),
			'Retrieve MANIFEST file.',
		) || diag( "Failed to open < MANIFEST file: $!." );

		if ( $opened_manifest )
		{
			while ( my $file = <$MANIFEST> )
			{
				chomp( $file );
				next if defined( $excluded_patterns ) && $file =~ /$excluded_patterns/;
				next unless $file =~ m/^lib[\\\/](.*)\.pm$/;

				my $module = $1;
				$module =~ s/[\\\/]/::/g;
				push( @$modules, $module );
			}
			close( $MANIFEST );
		}
	}

	return $modules;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Test-Dist-VersionSync/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Test::Dist::VersionSync


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/Test-Dist-VersionSync/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/test-dist-versionsync>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/test-dist-versionsync>

=item * MetaCPAN

L<https://metacpan.org/release/Test-Dist-VersionSync>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
