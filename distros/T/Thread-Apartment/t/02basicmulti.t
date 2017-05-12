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

$TestCommon::testtype = 'basic, multithreaded';

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
#	then pass to another thread via a TQD:
#	create a wrapped object
#
my $obj = Thread::Apartment->new(
	AptClass => 'ThirdBase',
	AptTimeout => 10,
	AptParams => [ 'lc' ]
);
TestCommon::report_result(\$testno, defined($obj), 'constructor', '', $@);

unless ($obj) {
	TestCommon::report_result(\$testno, 'skip', 'no object, skipping')
		foreach ($testno..$tests);
	die "Unable to continue, cannot create an object.";
}

my $tqd = Thread::Queue::Duplex->new(ListenerRequired => 1);
my $thread = threads->new(\&TestCommon::run_thread, $tqd, \$testno);
$tqd->wait_for_listener();
$tqd->enqueue_and_wait($obj, $batter);
sleep 2;
$thread->join();
