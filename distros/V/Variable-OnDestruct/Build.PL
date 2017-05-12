use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Variable::OnDestruct',
	license             => 'perl',
	dist_author         => 'Leon Timmermans <leont@cpan.org>',
	dist_version_from   => 'lib/Variable/OnDestruct.pm',
	configure_requires  => {
		'Module::Build' => 0.28,
	},
	build_requires      => {
		'ExtUtils::CBuilder' => 0,
		'Module::Build' => 0.28,
		'Test::More'    => 0,
	},
	requires => {
		perl            => 5.007003,
		Exporter        => 5.57,
	},
	meta_merge => {
		resources       => {
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Variable-OnDestruct',
			repository  => 'http://github.com/Leont/variable-ondestruct/tree',
		},
		keywords        => [ 'destructor' ],
	},
	add_to_cleanup      => [ 'Variable-OnDestruct-*' ],
	create_makefile_pl  => 'small',
	sign                => 1,
);

$builder->create_build_script();
