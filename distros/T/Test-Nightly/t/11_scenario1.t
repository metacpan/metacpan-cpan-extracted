#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 3;

my $report = '/tmp/this_should_not_be_ever_created.txt';

&cleanup;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly' ) };

#==================================================
# SCENARIO ONE
# 	- There are no tests found.
#
#==================================================

my $test_obj1 = Test::Nightly->new({base_directories => ['t/data/module/no_tests_in_here']});

$test_obj1->run_tests({
	test_file_format => ['.b'],
});

#==================================================
# Check that test_file_format has been set 
# to ".b" 
#==================================================

ok($test_obj1->test_file_format()->[0] eq '.b', 'test_file_format has been set to ".b"');

$test_obj1->generate_report({report_output => $report});

my $file_exists = 0;
if (-e $report) {
	$file_exists = 1;
}

#==================================================
# Check that no report generates
#==================================================
ok(!$file_exists, 'Report was not generated, as expected');

# Just in case tests from Scenario one didn't work

&cleanup;
sub cleanup {
	
	# Just incase it did get created!
	unlink ($report);
}
