#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 5;

my $report = '/tmp/passing_test_report.txt';

&cleanup;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly' ) };

&cleanup;

#==================================================
# SCENARIO FOUR
#	- We only have one test - test.pl
#   - Everything is passed into new
#	- Test directory is the base directory
# 
#==================================================

my $test_obj1 = Test::Nightly->new({
	base_directories 	=> ['t/data/module/'],
	run_tests			=> {
		test_directory_format	=> ['.'],
		test_file_format	=> ['.pl'],
	},
	generate_report	=> {
		report_output => $report, 
	},
});

ok($test_obj1->test_file_format()->[0] eq '.pl', 'test_file_format set to .pl');

ok($test_obj1->test_directory_format()->[0] eq '.', 'test_directory_format set to .');

my %test_output_format = (
	't/data/module' => [
	{
		'test' => 'test.pl',
		'status' => 'failed'
	}
	]
);

is_deeply($test_obj1->test()->tests(), \%test_output_format, 'run() - tests() has the correct structure');

my $file_exists = 0;
if (-e $report) {
	$file_exists = 1;
}

ok($file_exists, 'Report was generated, as expected');

&cleanup();

sub cleanup {
	
	unlink ($report);

}
