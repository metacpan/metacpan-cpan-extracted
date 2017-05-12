#!/usr/bin/perl -w

use lib qw( ./blib/lib ../blib/lib );

use strict;
use Test::More tests => 3;

my $report = '/tmp/test_nightly_report.txt';

&cleanup;

#==================================================
# Check that module loads
#==================================================

BEGIN { use_ok( 'Test::Nightly' ) };

#==================================================
# SCENARIO THREE
# 	- We have passing and failing tests
#	- Methods are called seperately
#	- test extention is '.b'
# 
#==================================================

my $nightly = Test::Nightly->new({
	base_directories => ['t/data/module/'],
});

$nightly->run_tests();

$nightly->generate_report({
	report_output => $report,
});

#==================================================
# Check that the report_output has been set
#==================================================

ok($nightly->report_output() eq $report, 'report_output() was set to '.$report);

my $file_exists = 0;
if (-e $report) {
	$file_exists = 1;
}

#==================================================
# Check that the file exists
#==================================================

ok($file_exists, 'Report was generated as expected');

&cleanup;

sub cleanup {
	
	# Just incase it did get created!
	unlink ($report);
}
