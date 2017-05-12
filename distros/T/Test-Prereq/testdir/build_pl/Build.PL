#!perl
use strict;
use warnings;

use Module::Build;

my $class = do {
	if( eval "use Test::Manifest 2.00; 1" ) {
		Test::Manifest->get_module_build_subclass;
		}
	else {
		'Module::Build';
		}
	};
	
my $build = $class->new(
	module_name       => 'Test::Prereq',
	dist_abstract     => 'Ensure a build file lists all pre-requisites',
	dist_version_from => 'lib/Prereq.pm',
	license           => 'perl',
	dist_author       => 'brian d foy <bdfoy@cpan.org>',

	recommends => {
		'Test::Manifest'         => '2.00',
		},

	build_requires => {
		'perl'                   => '5.010',
		'Test::Builder'          => '0',
		'Test::Builder::Tester'  => '0',
		},

	test_requires => {
		'Test::More'             => '0',
		},

	requires       => {
		'Module::Build'          => '0',
		'Module::CoreList'       => '0',
		'Module::Info'           => '0',
		},

	pm_files        => {
		'lib/Prereq.pm' => 'lib/Test/Prereq.pm',
		'lib/Build.pm'  => 'lib/Test/Prereq/Build.pm',
		},

	add_to_cleanup  => [ qw|Test-*| ], 
	);

$build->create_build_script;
