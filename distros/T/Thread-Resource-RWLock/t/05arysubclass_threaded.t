use vars qw($loaded);

BEGIN {
	$| = 1;
#	print STDERR "Note: some tests have significant delays...\n";
	print "1..12\n";
}
END {print "not ok 1\n" unless $loaded;}

package LockedObject;

use threads;
use threads::shared;
use Thread::Queue::Queueable;
use Thread::Resource::RWLock;

use base qw(Thread::Queue::Queueable Thread::Resource::RWLock::Array);

use strict;
use warnings;

use constant LOCKOBJ_VALUE => 5;

sub new {
	my $class = shift;

	my @obj : shared = ();

	my $self = bless \@obj, $class;

	$self->[LOCKOBJ_VALUE] = 0;
#
#	init the locking members
#
	return $self->Thread::Resource::RWLock::adorn();
}

sub increment {
	return ++$_[0][LOCKOBJ_VALUE];
}

sub decrement {
	return --$_[0][LOCKOBJ_VALUE];
}

sub getValue {
	return $_[0][LOCKOBJ_VALUE];
}

sub setValue {
	return $_[0][LOCKOBJ_VALUE] = $_[1];
}
#
#	TQQ method override
#
sub redeem {
	my ($class, $self) = @_;

	return bless $self, $class;
}

package main;
use threads;
use threads::shared;
use Thread::Queue::Duplex;

use strict;
use warnings;

my $testtype = 'hash subclass, multithreaded';

sub report_result {
	my ($testno, $result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $$testno # skip $testmsg for $testtype\n" :
			"ok $$testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $$testno # $testmsg $notokmsg for $testtype\n";
	}
	$$testno++;
}
#
#	prelims: use shared test count for eventual
#	threaded tests
#
my $testno : shared = 1;
$loaded = 1;

report_result(\$testno, 1, 'load');
#
#	in threaded app:
#
my $resource = LockedObject->new();

report_result(\$testno, $resource && $resource->isa('Thread::Resource::RWLock'),
	'subclass constructor');

my $tqdA = Thread::Queue::Duplex->new();
my $tqdB = Thread::Queue::Duplex->new();
my $tqdC = Thread::Queue::Duplex->new();
#
#	Test cases:
#		2 threads, each readlocks and sleeps a bit before
#		unlocking: both should succeed
#
my $thrdA = threads->new(\&test1thrdA, $tqdA);
my $thrdB = threads->new(\&test1thrdB, $tqdB);

my $idA = $tqdA->enqueue($resource);
my $idB = $tqdB->enqueue($resource);

my $resultA = $tqdA->wait($idA);
my $resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();

report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 2)),
	'2 readers');

#
#	2 threads:
#	1st readlocks, verifies timestamp token, sleeps a bit
#	2nd thread attempts write lock NB: should fail, then sleeps a bit
#	1st reader unlocks
#	2nd attempts writelock NB, which should succeed, increments, then unlocks
#
$resource->setValue(0);
$thrdA = threads->new(\&test2thrdA, $tqdA);
$thrdB = threads->new(\&test2thrdB, $tqdB);

$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();
report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 2)),
	'read + NB write');

#
#	2 threads:
#	each attempts writelock NB. One succeeds, increments resource,
#		sleeps a bit, unlocks.
#	Failing thread readlocks, and should see the incremented value
#
$resource->setValue(0);
$thrdA = threads->new(\&test3thrdA, $tqdA);
$thrdB = threads->new(\&test3thrdA, $tqdB);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();

report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 1)),
	'2 writers');
#
#	2 threads:
#	1st writelocks, increments, sleeps a bit.
#	2nd attempts readlock NB, should fail, sleeps a bit
#	1st unlocks
#	2nd attempts readlock NB, succeeds, verifies increment
#		and unlocks
#
$resource->setValue(0);
$thrdA = threads->new(\&test4thrdA, $tqdA);
$thrdB = threads->new(\&test4thrdB, $tqdB);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();
report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 1)),
	'writer + NB read');
#
#	2 threads:
#	each writelocks and increments
#	1st to get lock then (value == 1) downgrades to readlock
#	sleeps a bit, and unlocks.
#	2nd then gets write lock, sees increment of 1st, increments, and unlocks
#
$resource->setValue(0);
$thrdA = threads->new(\&test5thrdA, $tqdA);
$thrdB = threads->new(\&test5thrdA, $tqdB);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();
report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 2)),
	'2 writers, 1 downgrade');
#
#	2 threads:
#	1st readlocks and sleeps
#	2nd writelocks_timed for less than sleep interval: should fail.
#	2nd writelocks_timed for > sleep interval: should succeed
#
$resource->setValue(0);
$thrdA = threads->new(\&test6thrdA, $tqdA);
$thrdB = threads->new(\&test6thrdB, $tqdB);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();
report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 1)),
	'timed writelock');
#
#	2 threads:
#	1st writelocks and sleeps
#	2nd readlocks_timed for less than sleep interval: should fail.
#	2nd readlocks_timed for > sleep interval: should succeed
#
$resource->setValue(0);
$thrdA = threads->new(\&test7thrdA, $tqdA);
$thrdB = threads->new(\&test7thrdB, $tqdB);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);

$thrdA->join();
$thrdB->join();
report_result(\$testno,
	($resultA && $resultA->[0] && $resultB && $resultB->[0] &&
		($resource->getValue() == 1)),
	'timed readlock');
#
#	3 threads:
#	2 readlock, increment, and sleep
#	3rd writelocks.
#	3rd should see results of prior 2.
#
$resource->setValue(0);
$thrdA = threads->new(\&test8thrdA, $tqdA);
$thrdB = threads->new(\&test8thrdA, $tqdB);
my $thrdC = threads->new(\&test8thrdB, $tqdC);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);
my $idC = $tqdC->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);
my $resultC = $tqdC->wait($idC);

$thrdA->join();
$thrdB->join();
$thrdC->join();
report_result(\$testno,
	($resultA && $resultA->[0] &&
	$resultB && $resultB->[0] &&
	$resultC && $resultC->[0] &&
	($resource->getValue() == 2)),
	'multiple readlocks + writelock');
#
#	2 threads:
#	1st readlocks, increments, and sleeps,
#	2nd writelocks.
#	1st wakes, upgrades, increments, then unlocks.
#	2nd should then see both increments
#
$resource->setValue(0);
$thrdA = threads->new(\&test9thrdA, $tqdA);
$thrdB = threads->new(\&test9thrdB, $tqdB);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);
$thrdA->join();
$thrdB->join();
report_result(\$testno,
	($resultA && $resultA->[0] &&
	$resultB && $resultB->[0] &&
	($resource->getValue() == 2)),
	'readlock upgrade');

#
#	3 threads:
#	2 writelock, increment, and unlock
#	3rd sleeps a bit, readlocks.
#	3rd should see results of prior 2.
#
$resource->setValue(0);
$thrdA = threads->new(\&test10thrdA, $tqdA);
$thrdB = threads->new(\&test10thrdA, $tqdB);
$thrdC = threads->new(\&test10thrdB, $tqdC);
$idA = $tqdA->enqueue($resource);
$idB = $tqdB->enqueue($resource);
$idC = $tqdC->enqueue($resource);

$resultA = $tqdA->wait($idA);
$resultB = $tqdB->wait($idB);
$resultC = $tqdC->wait($idC);

$thrdA->join();
$thrdB->join();
$thrdC->join();
report_result(\$testno,
	($resultA && $resultA->[0] &&
	$resultB && $resultB->[0] &&
	$resultC && $resultC->[0] &&
	($resource->getValue() == 2)),
	'multiple writelocks + readlock');

#################################################################
#
#	TEST CASE SUPPORT ROUTINES
#
#################################################################
#
#		2 threads, each readlocks and sleeps a bit before
#		unlocking: both should succeed
#
sub test1thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->read_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 2;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test1thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->read_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 2;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

#
#	2 threads:
#	1st readlocks, verifies timestamp token, sleeps a bit
#	2nd thread attempts write lock NB: should fail, then sleeps a bit
#	1st reader unlocks
#	2nd attempts writelock NB, which should succeed, increments, then unlocks
#
sub test2thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->read_lock();

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 3;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test2thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;

	sleep 1;

	my $token = $resource->write_lock_nb();

	if ($token) {
	$tqd->respond($id, undef);
	$resource->unlock();
	return 1;
	}

	sleep 4;

	$token = $resource->write_lock_nb();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

#
#	2 threads:
#	each attempts writelock NB. One succeeds, increments resource,
#		sleeps a bit, unlocks.
#	Failing thread readlocks, and should see the incremented value
#
sub test3thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->write_lock_nb();

	if ($token) {
#
#	got the lock
#
		$resource->increment();
		sleep 2;
	}
	else {
		$token = $resource->read_lock();

		$tqd->respond($id, undef),
		$resource->unlock(),
		return 1
			unless $token && ($token > 0);

		$tqd->respond($id, undef),
		$resource->unlock(),
		return 1
			unless ($resource->getValue() == 1);
	}

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

#
#	2 threads:
#	1st writelocks, increments, sleeps a bit.
#	2nd attempts readlock NB, should fail, sleeps a bit
#	1st unlocks
#	2nd attempts readlock NB, succeeds, verifies increment
#		and unlocks
#
sub test4thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 2;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test4thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	sleep 1;	# let first get the lock
	my $token = $resource->read_lock_nb();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		if $token;

	sleep 3;

	$token = $resource->read_lock_nb();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless ($resource->getValue() == 1) &&
			$resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}


#
#	2 threads:
#	each writelocks and increments
#	1st to get lock then (value == 1) downgrades to readlock
#	sleeps a bit, and unlocks.
#	2nd then gets write lock, increments, and unlocks
#
sub test5thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();

	if ($resource->getValue() == 1) {
		my $nexttoken = $resource->read_lock();
		$tqd->respond($id, undef),
		$resource->unlock(),
		return 1
			unless $nexttoken && ($nexttoken < 0);

		sleep 2;

		$tqd->respond($id, undef),
		$resource->unlock(),
		return 1
			unless ($resource->getValue() == 1) &&
				$resource->unlock($token);
	}
	else {
		$tqd->respond($id, undef),
		$resource->unlock(),
		return 1
			unless ($resource->getValue() == 2) &&
				$resource->unlock($token);
	}

	$tqd->respond($id, 1);
	return 1;
}

#
#	2 threads:
#	1st readlocks and sleeps
#	2nd writelocks_timed for less than sleep interval: should fail.
#	2nd writelocks_timed for > sleep interval: should succeed
#
sub test6thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->read_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 10;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test6thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	sleep 2;

	my $token = $resource->write_lock_timed(3);
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		if $token;

	sleep 8;

	$token = $resource->write_lock_timed(3);
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

#
#	2 threads:
#	1st writelocks and sleeps
#	2nd readlocks_timed for less than sleep interval: should fail.
#	2nd readlocks_timed for > sleep interval: should succeed
#
sub test7thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 10;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test7thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	sleep 3;
	my $token = $resource->read_lock_timed(3);
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		if $token;

	sleep 7;

	$token = $resource->read_lock_timed(3);
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

#
#	3 threads:
#	2 readlock, increment, and sleep
#	3rd writelocks.
#	3rd should see results of prior 2.
#
sub test8thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->read_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 2;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test8thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	sleep 1;
	my $token = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless ($resource->getValue() == 2) &&
			$resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}
#
#	2 threads:
#	1st readlocks, increments, and sleeps,
#	2nd writelocks.
#	1st wakes, upgrades, increments, then unlocks.
#	2nd should then see both increments
#	(ie, 2nd isn't granted til 1 upgrades & unlocks)
#
sub test9thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->read_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 2;
#
#	upgrade
#
	my $nexttoken = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $nexttoken && ($nexttoken < 0);

	$resource->increment();

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test9thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	sleep 1;
	my $token = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless ($resource->getValue() == 2) &&
			$resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

#
#	3 threads:
#	2 writelock, increment, and unlock
#	3rd sleeps a bit, readlocks.
#	3rd should see results of prior 2.
#
sub test10thrdA {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	my $token = $resource->write_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$resource->increment();
	sleep 1;

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}

sub test10thrdB {
	my $tqd = shift;

	my $req = $tqd->dequeue();
	my ($id, $resource) = @$req;
	sleep 1;
	my $token = $resource->read_lock();
	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless $token && ($token > 0);

	$tqd->respond($id, undef),
	$resource->unlock(),
	return 1
		unless ($resource->getValue() == 2) &&
			$resource->unlock($token);

	$tqd->respond($id, 1);
	return 1;
}
