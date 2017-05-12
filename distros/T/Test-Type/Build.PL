use 5.006;
use strict;
use warnings;

use Module::Build;


my $class = Module::Build->subclass(
	code =>
	q|
		# Override 'test' to support running extended tests in the xt/
		# directory.
		sub ACTION_test
		{
			my ( $self ) = @_;

			$self->recursive_test_files(1);

			$self->test_files( 't', 'xt' )
				if $ENV{'RELEASE_TESTING'};

			return $self->SUPER::ACTION_test();
		}

		# Force running extended tests when testing the distribution.
		sub ACTION_disttest
		{
			my ( $self ) = @_;

			local $ENV{ RELEASE_TESTING } = 1;

			return $self->SUPER::ACTION_disttest();
		}
	|,
);

my $builder = $class->new(
	module_name         => 'Test::Type',
	license             => 'Perl_5',
	dist_author         => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from   => 'lib/Test/Type.pm',
	build_requires      =>
	{
		'Test::Builder::Tester' => '0',
		'Test::FailWarnings'    => '0',
	},
	requires            =>
	{
		'perl'                  => 5.006,
		'Carp'                  => '0',
		'Data::Validate::Type'  => '1.5.0',
		'Exporter'              => '5.57', # required for "use Exporter qw( import );"
		'Test::More'            => '0.94',
	},
	add_to_cleanup      =>
	[
		'Test-Type-*',
	],
	create_makefile_pl  => 'traditional',
	configure_requires  =>
	{
		'Module::Build'         => 0,
	},
	meta_merge          =>
	{
		resources               =>
		{
			repository  => 'https://github.com/guillaumeaubert/Test-Type',
			homepage    => 'https://metacpan.org/release/Test-Type',
			bugtracker  => 'https://github.com/guillaumeaubert/Test-Type/issues',
		},
	},
);

$builder->create_build_script();
