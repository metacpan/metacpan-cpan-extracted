#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 2;

SKIP: {

	eval { require Module::Build };

	skip "Module::Build not installed", 2 if $@;


#==================================================
# Check that module loads
#==================================================

	BEGIN { use_ok( 'Test::Nightly' ) };

#==================================================
# SCENARIO FIVE
#	- We are using build.
#   - Everything is passed into new
#	- Test directory t
# 
#==================================================

	my $test_obj1 = Test::Nightly->new({
		base_directories 	=> ['t/data/module_build/'],
		build_script		=> 'Build.PL',
		run_tests			=> {
			build_type	=> 'build',
		},
	});

	my %test_output_format = (
		't/data/module_build/t' => [
			{
				'test' => 't/001_test_that_passes.t',
				'status' => 'passed'
			},
			{
				'test' => 't/002_test_that_fails.t',
				'status' => 'failed'
			},
			{
				'test' => 't/003_test_that_passes.t',
				'status' => 'passed'
			}
		]
	);

	is_deeply($test_obj1->test()->tests(), \%test_output_format, 'run() - tests() has the correct structure');	

}
