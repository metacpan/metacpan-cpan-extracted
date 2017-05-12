#
#	Thread::Apartment test script
#
use Config;
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 47;

	die "This Perl is not configured to support threads."
		unless $Config{useithreads};

	print STDERR
"\n *** Note: some tests have significant delays.
 *** Also, some tests on some platforms with some versions of
 *** Perl will report several (harmless) \"Scalars leaked: 1\"
 *** warnings which can be ignored.
";
#"\n *** Note: some tests have significant delays.
#Also note tests may exit with the harmless warning:
#	'A thread exited while N threads were running';
#";
	$^W= 1;
	$| = 1;
	print "1..$tests\n";
}

END {print "not ok 1\n" unless $loaded;}

#
#	tests:
#	1. load OK
#	2. Create a wrapped object wo/ providing TQD/thread
#		(also creates a 2nd T::A object for async/closure testing)
#	3. Test simple method call
#	4. Test fully qualified method call
#	5. Test array-returning method call
#	6. Test attempt to access private method
#	7. Test for nonexistant method name
#	8. Test for AUTOLOADing method name
#	9. Test simplex method call
#	10. Test urgent method call
#	11. Test urgent, simplex method call
#	12. Test passing multiple, complex parameters
#	13. Test calling encapsulated TAS object
#	14. Test method call returning an error
#	15. Test method call returning an object
#	16. Test async method calls between objects
#		(also tests passing closures)
#	17. Test various closure calls between objects
#		(also tests returning closures)
#	18. Test timed method calls for timeout
#	19. Pass object to another thread and repeat tests (3-15)
#	20. Create TQD/thread externally and repeat tests (3-15)
#	21. Create an I/O object and repeat tests (3-15)
#	22. test ref counting
#	23. install base thread in a T::A as a MuxServer and repeat (3-15)
#
use TestCommon;
use threads;
use threads::shared;
use Thread::Queue::Duplex;
use Thread::Apartment;
use Thread::Apartment::Server;
use Thread::Apartment::EventServer;
use Thread::Apartment::Client;
use Batter;
use ThirdBase;

use strict;
use warnings;

$TestCommon::testtype = 'basic, single threaded';
#
#	prelims: use shared test count for eventual
#	threaded tests
#
my $testno : shared = 1;
$loaded = 1;

TestCommon::report_result(\$testno, 1, 'load');
#
#	create a async/closure test object
#
my $batter = Thread::Apartment->new(
	AptClass => 'Batter',
	AptTimeout => 10
);
TestCommon::report_result(\$testno, defined($batter), 'simple constructor', '', $@);

unless ($batter) {
	TestCommon::report_result(\$testno, 'skip', 'no test object, skipping')
		foreach ($testno..$tests);
	die "Unable to continue, cannot create an object.";
}
#
#	create a wrapped object
#
my $obj = Thread::Apartment->new(
	AptClass => 'ThirdBase',
	AptTimeout => 5,
	AptParams => [ 'lc' ]
);
TestCommon::report_result(\$testno, defined($obj), 'constructor', '', $@);

unless ($obj) {
	TestCommon::report_result(\$testno, 'skip', 'no object, skipping')
		foreach ($testno..$tests);
	die "Unable to continue, cannot create an object.";
}
#
#	first run in our thread; on return,
#	our object is "dead", i.e., has been stopped/joined
#
TestCommon::run($obj, $batter, \$testno);

$batter->stop();

