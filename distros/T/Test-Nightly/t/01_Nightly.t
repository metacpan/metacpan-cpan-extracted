#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 5;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly' ) };

#==================================================
# Check module methods
#==================================================

my @methods = qw(new run_tests generate_report);
can_ok('Test::Nightly', @methods);

eval {Test::Nightly->new()};

#==================================================
# Check correct error message is added when there 
# is no base_directories supplied
#==================================================

like($@, qr/Test::Nightly::new\(\) - \"base_directories\" must be supplied/, 'new() - errors() has the correct error when no base_directories are supplied');

my $test_obj1 = Test::Nightly->new({base_directories => ['t/data/module/']});


#==================================================
# Check that modules hass the correct data 
# structure
#==================================================

my @module_structure = (
	{
		'build_script' => 'Makefile.PL',
		'directory' => 't/data/module/'
	}
);

is_deeply($test_obj1->modules(), \@module_structure, '_find_modules - The correct module structure has been found');


#==================================================
# Check that it skips makefiles that contain a 
# a space.
#==================================================

eval{my $test_obj2 = Test::Nightly->new({
	base_directories	=> ['t/data/module/'],
	build_script		=> 'Makefile Space.PL',
})};

like($@, qr/Test::Nightly::_find_modules\(\): Supplied \"build_script\" can not contain a space/, '_find_modules() - croaks when makefile contains a space');

