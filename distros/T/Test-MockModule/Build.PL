use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Test::MockModule',
	create_license      => 1,
	license             => 'perl',
	dist_author         => [q{Current Maintainer: Geoff Franks <gfranks@cpan.org>}, q{Original Author: Simon Flack <simonflk _AT_ cpan.org>}],
	meta_merge => {
		resources => {
			homepage   => 'https://github.com/geofffranks/test-mockmodule',
			bugtracker => 'https://github.com/geofffranks/test-mockmodule/issues',
			repository => 'git://github.com/geofffranks/test-mockmodule.git',
		},
	},

	configure_requires => {
		'Module::Build' => '0.4234',
	},
	requires => {
	    'perl'                => 5.006,
		'Carp'                => 0,
		'Scalar::Util'        => 0,
		'SUPER'               => '1.20',
	},
	test_requires => {
		'Test::More'          => 0.88,
		'Test::Warnings'      => 0
	},

	add_to_cleanup => [
		'Test-MockModule-*',
		'cover_db',
		'*.rpm',
		'*.deb',
	]
);

$builder->create_build_script();
