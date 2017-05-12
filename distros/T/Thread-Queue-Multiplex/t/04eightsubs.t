use strict;
use warnings;
use vars qw($loaded);
BEGIN {
	unshift @INC, './t';
	my $tests = 146;
	$^W= 1;
	$| = 1;
	print "1..$tests\n";
}

END {print "not ok $TestCommon::testno\n" unless $loaded;}

use TestCommon;
use TestCommon qw(report_result);

$loaded = 1;
report_result(1, 'load module');
#
#	runs the tests
#
TestCommon->run_test($ARGV[0] || 0, 8);
