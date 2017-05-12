#
#	Thread::Apartment test script
#
use Config;
use vars qw($tests $loaded);
BEGIN {
	push @INC, './t';
	$tests = 48;

	die "This Perl is not configured to support threads."
		unless $Config{useithreads};

	$^W= 1;
	$| = 1;
	print "1..$tests\n";
}

END {print "not ok 1\n" unless $loaded;}

use TestCommon;
use threads;
use threads::shared;
use Thread::Queue::Duplex;
use Thread::Apartment;
use Thread::Apartment::Server;
use Thread::Apartment::Client;
use Batter;
use ThirdBase;

use strict;
use warnings;

$TestCommon::testtype = 'pooled, multithreaded';

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
#	now use an externally provided/pooled thread/TQD, which will
#	create a new TQD for us
#
my $result = Thread::Apartment->create_pool(AptPoolSize => 4, AptMaxPending => 10);
TestCommon::report_result(\$testno, defined($result), 'create thread pool', '', $@);

unless ($result) {
	TestCommon::report_result(\$testno, 'skip', 'no object, skipping')
		foreach ($testno..$tests);
	die "Unable to continue, cannot create a thread pool.";
}

my $obj = Thread::Apartment->new(
	AptClass => 'ThirdBase',
	AptTimeout => 10,
	AptParams => [ 'lc' ]
);
TestCommon::report_result(\$testno, defined($obj), 'pooled thread constructor', '', $@);

unless ($obj) {
	TestCommon::report_result(\$testno, 'skip', 'no object, skipping')
		foreach ($testno..$tests);
	die "Unable to continue, cannot create a pooled threaded object.";
}

my $tqd = Thread::Queue::Duplex->new(ListenerRequired => 1);
my $thread = threads->new(\&TestCommon::run_thread, $tqd, \$testno);
$tqd->wait_for_listener();
$tqd->enqueue_and_wait($obj, $batter, 'ThirdBase');
$thread->join();
