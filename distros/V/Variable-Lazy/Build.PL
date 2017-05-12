use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Variable::Lazy',
	license             => 'perl',
	dist_author         => 'Leon Timmermans <leont@cpan.org>',
	dist_version_from   => 'lib/Variable/Lazy.pm',
	configure_requires  => {
		'Module::Build'         => 0,
	},
	build_requires => {
		'ExtUtils::CBuilder'    => 0,
		'Module::Build'         => 0,
		'Test::More'            => 0,
	},
	requires            => {
		perl                    => 5.008,
		'B::Hooks::EndOfScope'  => 0,
		'Devel::Declare'        => 0,
		Exporter                => 5.57,
		'namespace::clean'      => 0,
	},
	meta_merge => {
		resources      => {
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Variable-Lazy',
			repository => 'http://github.com/Leont/variable-lazy/tree',
		},
		keywords       => [ 'lazy', 'laziness' ],
	},
	add_to_cleanup      => [ 'Variable-Lazy-*' ],
	create_makefile_pl  => 'small',
	sign                => 1,
);

$builder->create_build_script();
