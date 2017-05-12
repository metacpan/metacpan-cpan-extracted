#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 5;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly::Test' ) };

my @methods = qw(new run);

#==================================================
# Check module methods
#==================================================
can_ok('Test::Nightly::Test', @methods);

my @modules = (
	{
		directory 		=> 't/data/module/' ,
		build_script	=> 'Makefile.PL',
	},
);

my $test_obj1 = Test::Nightly::Test->new({
	modules					=> \@modules,
	test_directory_format 	=> ['fake_test_folder/'],
    test_file_format      	=> ['.pl'],   
});

#==================================================
# Check that the correct folder was retrieved
#==================================================

ok($test_obj1->test_directory_format()->[0] eq 'fake_test_folder/', 'new() - The correct folder format was retrieved');

#==================================================
# Check that the correct test file format was 
# retrieved
#==================================================

ok($test_obj1->test_file_format()->[0] eq '.pl', 'new() - The correct file format was retrieved');

my $test_obj2 = Test::Nightly::Test->new({
	modules	=> \@modules,
});

$test_obj2->run();

my %test_output_structure = (

	't/data/module/t' => [
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

is_deeply($test_obj2->tests(), \%test_output_structure, 'run() - tests() has the correct structure');





