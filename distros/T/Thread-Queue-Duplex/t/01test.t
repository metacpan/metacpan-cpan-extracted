use strict;
use warnings;
use vars qw($testno $loaded $srvtype);
BEGIN {
	my $tests = 80;
	print STDERR "Note: some tests have significant delays...\n";
	$^W= 1;
	$| = 1;
	print "1..$tests\n";
}

END {print "not ok $testno\n" unless $loaded;}

package Qable;
use Thread::Queue::Queueable;

use base qw(Thread::Queue::Queueable);

sub new {
	return bless {}, shift;
}

sub onEnqueue {
	my $obj = shift;
	my $class = ref $obj;
#	print STDERR "$class object enqueued\n";
	return $obj->SUPER::onEnqueue;
}

sub onDequeue {
	my ($class, $obj) = @_;
#	print STDERR "$class object dequeued\n";
	return $class->SUPER::onDequeue($obj);
}

sub onCancel {
	my $obj = shift;
#	print STDERR "Item cancelled.\n";
	1;
}

sub curse {
	my $obj = shift;
	return $obj->SUPER::curse;
}

sub redeem {
	my ($class, $obj) = @_;
	return $class->SUPER::redeem($obj);
}

1;

package SharedQable;
use Thread::Queue::Queueable;

use base qw(Thread::Queue::Queueable);

sub new {
	my %obj : shared = ( Value => 1);
	return bless \%obj, shift;
}

sub set_value {
	my $obj = shift;
	$obj->{Value}++;
	return 1;
}

sub get_value { return shift->{Value}; }

sub redeem {
	my ($class, $obj) = @_;
	return bless $obj, $class;
}

1;

package main;

use threads;
use threads::shared;
use Thread::Queue::Duplex;

$srvtype = 'init';

sub report_ok {

	print "ok $testno # ", shift, " for $srvtype\n";
	$testno++;
}

sub report_fail {

	print "not ok $testno # ", shift, " for $srvtype\n";
	$testno++;
}
#
#	test normal dequeue method
#
sub run_dq {
	my $q = shift;

	$q->listen;
	while (1) {
		my $left = $q->pending;

		my $req = $q->dequeue;
#print threads->self()->tid(), " run_dq dq'd\n";
		my $id = shift @$req;

		if ($req->[0] eq 'stop') {
			$q->respond($id, 'stopped');
			$q->ignore();
			last;
		}

		if ($req->[0] eq 'wait') {
			sleep($req->[1]);
		}

		if ($req->[1] && ref $req->[1] && (ref $req->[1] eq 'SharedQable')) {
			$req->[1]->set_value();
		}
#
#	ignore simplex msgs
#
		next
			unless $id;

		$q->marked($id) ?
			$q->respond($id, $q->get_mark($id)) :
			$q->respond($id, @$req);
	}
}
#
#	test nonblocking dequeue method
#
sub run_nb {
	my $q = shift;

	$q->listen;
	while (1) {
		my $req = $q->dequeue_nb;

		sleep 1, next
			unless $req;

#print "run_nb dq'd\n";
		my $id = shift @$req;

		$q->ignore(),
		$q->respond($id, 'stopped'),
		last
			if ($req->[0] eq 'stop');

#print STDERR join(', ', @$req), "\n";
		sleep($req->[1])
			if ($req->[0] eq 'wait');
#
#	ignore simplex msgs
#
		$q->respond($id, @$req)
			if $id;
	}
}
#
#	test timed dequeue method
#
sub run_until {
	my $q = shift;

	my $timeout = 2;
	$q->listen;
	while (1) {

		my $req = $q->dequeue_until($timeout);
		sleep 1, next
			unless $req;

#print "run_until dq'd\n";
		my $id = shift @$req;

		$q->ignore(),
		$q->respond($id, 'stopped'),
		last
			if ($req->[0] eq 'stop');

		sleep($req->[1])
			if ($req->[0] eq 'wait');
#
#	ignore simplex msgs
#
		$q->respond($id, @$req)
			if $id;
	}
}
#
#	acts as a requestor thread for class-level
#	wait tests
#
sub run_requestor {
	my $q = shift;

	$q->wait_for_listener;

	while (1) {
		my $id = $q->enqueue('request');
		my $resp = $q->wait($id);

		last
			if ($resp->[0] eq 'stop');
	}
	return 1;
}
#
#	test urgent dequeue method
#
sub run_urgent {
	my $q = shift;

	$q->listen;
	while (1) {
		my $req = $q->dequeue_urgent;

		sleep 1, next
			unless $req;

#print "run_urgent dq'd\n";
		my $id = shift @$req;

		$q->ignore(),
		$q->respond($id, 'stopped'),
		last
			if ($req->[0] eq 'stop');

		sleep($req->[1])
			if ($req->[0] eq 'wait');
#
#	ignore simplex msgs
#
		$q->respond($id, @$req)
			if $id;
	}
}

$testno = 1;

report_ok('load module');
#
#	create queue
#	spawn server thread
#	execute various requests
#	verify responses
#
#	test constructor
#
my $q = Thread::Queue::Duplex->new(ListenerRequired => 1);

report_ok('create queue');
#
#	test different kinds of dequeue
#
my @servers = (\&run_dq, \&run_nb, \&run_until);
my @types = ('normal', 'nonblock', 'timed');

my ($result, $id, $server);

my $start = $ARGV[0] || 0;
my $qable = Qable->new();
my $sharedqable = SharedQable->new();

foreach ($start..$#servers) {
	$server = threads->new($servers[$_], $q);
	$srvtype = $types[$_];
#
#	wait for a listener
#
	$q->wait_for_listener() ?
		report_ok('wait_for_listener()') :
		report_fail('wait_for_listener()');
#
#	test enqueue_simplex
#
	$id = $q->enqueue_simplex('foo', 'bar');
	defined($id) ?
		report_ok('enqueue_simplex()') :
		report_fail('enqueue_simplex()');
#
#	test enqueue
#
	$id = $q->enqueue('foo', 'bar');
	defined($id) ?
		report_ok('enqueue()') :
		report_fail('enqueue()');
#
#	test ready(); don't care about outcome
#	(prolly need eval here)
#
	$result = $q->ready($id);
	report_ok('ready()');
#
#	test wait()
#
	$result = $q->wait($id);

	(defined($result) &&
		($result->[0] eq 'foo') &&
		($result->[1] eq 'bar')) ?
		report_ok('wait()') :
		report_fail('wait()');
#
#	test dequeue_response
#
	$id = $q->enqueue('foo', 'bar');
	$result = $q->dequeue_response($id);
	(defined($result) &&
		($result->[0] eq 'foo') &&
		($result->[1] eq 'bar')) ?
		report_ok('dequeue_response()') :
		report_fail('dequeue_response()');
#
#	test Queueable enqueue
#
	$id = $q->enqueue('foo', $qable);
	defined($id) ?
		report_ok('enqueue() Queueable') :
		report_fail('enqueue() Queueable');

	$result = $q->wait($id);

	(defined($result) &&
		($result->[0] eq 'foo') &&
		(ref $result->[1]) &&
		(ref $result->[1] eq 'Qable')) ?
		report_ok('wait() Queueable') :
		report_fail('wait() Queueable');
#
#
#	test wait_until, enqueue_urgent
#
	$id = $q->enqueue('wait', 3);
	my $id1 = $q->enqueue('foo', 'bar');
	$result = $q->wait_until($id, 1);
	defined($result) ?
		report_fail('wait_until() expires') :
		report_ok('wait_until() expires');

	my $id2 = $q->enqueue_urgent('urgent', 'entry');
#
#	should get wait reply here
#
	$result = $q->wait_until($id, 5);
	defined($result) &&
		($result->[0] eq 'wait') ?
		report_ok('wait_until()') :
		report_fail('wait_until()');
#
#	should get urgent reply here
#
	$result = $q->wait($id2);
	defined($result) &&
		($result->[0] eq 'urgent') ?
		report_ok('enqueue_urgent()') :
		report_fail('enqueue_urgent()');
#
#	should get normal reply here
#
	$result = $q->wait($id1);
	defined($result) && ($result->[0] eq 'foo') ?
		report_ok('enqueue()') :
		report_fail('enqueue()');
#
#	test wait_any: need to queue up several
#
	my %ids = ();

	map { $ids{$q->enqueue('foo', 'bar')} = 1; } (1..10);
#
#	repeat here until all ids respond
#
	my $failed;
	while (keys %ids) {
		$result = $q->wait_any(keys %ids);
		$failed = 1,
		last
			unless defined($result) &&
				(ref $result) &&
				(ref $result eq 'HASH');
		map {
			$failed = 1
				unless delete $ids{$_};
		} keys %$result;
		last
			if $failed;
	}
	$failed ?
		report_fail('wait_any()') :
		report_ok('wait_any()');
#
#	test wait_any_until
#
	%ids = ();

	$ids{$q->enqueue('wait', '3')} = 1;
	map { $ids{$q->enqueue('foo', 'bar')} = 1; } (2..10);
	$failed = undef;

	$result = $q->wait_any_until(1, keys %ids);
	if ($result) {
		report_fail('wait_any_until()');
	}
	else {
		while (keys %ids) {
			$result = $q->wait_any_until(5, keys %ids);
			$failed = 1,
			last
				unless defined($result) &&
					(ref $result) &&
					(ref $result eq 'HASH');
			map {
				$failed = 1
					unless delete $ids{$_};
			} keys %$result;
			last
				if $failed;
		}
		$failed ?
			report_fail('wait_any_until()') :
			report_ok('wait_any_until()');
	}
#
#	test wait_all
#
	%ids = ();
	map { $ids{$q->enqueue('foo', 'bar')} = 1; } (1..10);
#
#	test available()
#
	sleep 1;
	my @avail = $q->available;
	scalar @avail ?
		report_ok('available (array)') :
		report_fail('available (array)');

	$id = $q->available;
	$id ?
		report_ok('available (scalar)') :
		report_fail('available (scalar)');

	$id = keys %ids;
	@avail = $q->available($id);
	scalar @avail ?
		report_ok('available (id)') :
		report_fail('available (id)');
#
#	make sure all ids respond
#
	$result = $q->wait_all(keys %ids);
	unless (defined($result) &&
		(ref $result) &&
		(ref $result eq 'HASH') &&
		(scalar keys %ids == scalar keys %$result)) {
		report_fail('wait_all()');
	}
	else {
		map { $failed = 1 unless delete $ids{$_}; } keys %$result;
		($failed || scalar %ids) ?
			report_fail('wait_all()') :
			report_ok('wait_all()');
	}
#
#	test wait_all_until
#
	%ids = ();
	map { $ids{$q->enqueue('wait', '1')} = 1; } (1..10);
#
#	make sure all ids respond
#
	$result = $q->wait_all_until(1, keys %ids);
	if (defined($result)) {
		report_fail('wait_all_until()');
	}
	else {
	# may need a warning print here...
		$result = $q->wait_all_until(20, keys %ids);
		map { $failed = 1 unless delete $ids{$_}; } keys %$result;
		($failed || scalar keys %ids) ?
			report_fail('wait_all_until()') :
			report_ok('wait_all_until()');
	}
#
#	test cancel()/cancel_all():
#	post a waitop
# 	post a no wait
#	wait a bit for server to pick up the first
#	cancel the nowait
#	check the pending count for zero
#	wait for waitop to finish
#
	$id = $q->enqueue('wait', 5);
	$id1 = $q->enqueue('foo', 'bar');
	$result = $q->wait_until($id, 3);
	$q->cancel($id1);
#print "Cancel: pending :", $q->pending, "\n";
	$q->pending ? report_fail('cancel()') : report_ok('cancel()');
	$result = $q->wait($id);
#
#	do same, but add multiple and cancel all
#
	$id = $q->enqueue('wait', 5);
	$id1 = $q->enqueue('first', 'bar');
	$id2 = $q->enqueue('second', 'bar');
	$result = $q->wait_until($id, 1);
	$q->cancel_all();
#print "Cancel all: pending :", $q->pending, " avail ", $q->available, "\n";
	$q->pending || $q->available ?
		report_fail('cancel_all()') : report_ok('cancel_all()');
#
#	kill the thread; also tests urgent i/f
#
	$id = $q->enqueue_urgent('stop');
	$id ? report_ok('enqueue_urgent()') :
		report_fail('enqueue_urgent()');
	$server->join;
#
#	wait for response, then test enqueue wo/ a listener
#
	$result = $q->wait($id);
	$q->enqueue('no listener') ?
		report_fail('enqueue() wo/ listener') :
		report_ok('enqueue() wo/ listener');

}	#end foreach server method
#
#	now test the class-level waits:
#	create an add'l queue
#	create a listener thread w/ old queue
#	create requestor thread w/ new queue
#
	my $newq = Thread::Queue::Duplex->new(ListenerRequired => 1);
	$server = threads->new($servers[0], $q);
	$srvtype = $types[0];
	$q->wait_for_listener();
#
#	test shared Queueable enqueue
#
	$id = $q->enqueue('foo', $sharedqable);
	defined($id) ?
		report_ok('enqueue() shared Queueable') :
		report_fail('enqueue() shared Queueable');

	$result = $q->wait($id);

	(defined($result) &&
		($result->[0] eq 'foo') &&
		(ref $result->[1]) &&
		(ref $result->[1] eq 'SharedQable') &&
		($result->[1]->get_value == 2)) ?
		report_ok('wait() Queueable') :
		report_fail('wait() Queueable');


	my $requestor = threads->new(\&run_requestor, $newq);
	$newq->listen();
	my @qs = ();
#
#	post request to listener
#	wait on both queues
#
	$id = $q->enqueue('wait', 3);
print "ID is undef!!!\n" unless defined($id);
#	@qs = Thread::Queue::Duplex->wait_any([$q, $id], [$newq]);
	@qs = Thread::Queue::Duplex->wait_any([$q, $id], $newq);
	unless (scalar @qs) {
		report_fail('class-level wait_any()');
	}
	else {
#
#	should get the newq only here...
#
		unless ((scalar @qs == 1) && ($qs[0] eq $newq)) {
			report_fail('class-level wait_any()');
		}
		else {
			my $req = $newq->dequeue();
			$newq->respond(shift @$req, 'ok');
		}
#
#	wait for other queue
#
		my $resp = $q->wait($id);
		report_ok('class-level wait_any()');
	}
#
#	now timed wait_any
#
	$id = $q->enqueue('wait', 5);
	@qs = Thread::Queue::Duplex->wait_any_until(3, [$q, $id], [$newq]);
	unless (scalar @qs) {
		report_fail('class-level wait_any_until()');
	}
	else {
#
#	should get the newq only here...
#
		unless ((scalar @qs == 1) && ($qs[0] eq $newq)) {
			report_fail('class-level wait_any_until()');
		}
		else {
			my $req = $newq->dequeue();
			$newq->respond(shift @$req, 'ok');
		}
#
#	wait for other queue
#
		my $resp = $q->wait($id);
		report_ok('class-level wait_any_until()');
	}
#
#	now wait_all
#
	$id = $q->enqueue('wait', 3);
	@qs = Thread::Queue::Duplex->wait_all([$q, $id], [$newq]);
	unless (scalar @qs == 2) {
		report_fail('class-level wait_all()');
	}
	else {
		foreach (@qs) {
			if ($_ eq $newq) {
				my $req = $newq->dequeue();
				$newq->respond(shift @$req, 'ok');
			}
			else {
#
#	wait for other queue
#
				my $resp = $q->wait($id);
			}
		}
		report_ok('class-level wait_all()');
	}
#
#	now timed wait_all
#
	$id = $q->enqueue('wait', 3);
	@qs = Thread::Queue::Duplex->wait_all_until(1, [$q, $id], [$newq]);
#
#	shouldn't get anything first time thru
#
	if (@qs) {
		report_fail('class-level wait_all_until()');
	}
	else {
		@qs = Thread::Queue::Duplex->wait_all_until(5, [$q, $id], [$newq]);
		unless (scalar @qs == 2) {
			report_fail('class-level wait_all_until()');
		}
		else {
			foreach (@qs) {
				if ($_ eq $newq) {
					my $req = $newq->dequeue();
					$newq->respond(shift @$req, 'stop');
				}
				else {
#
#	wait for other queue
#
					my $resp = $q->wait($id);
				}
			}
			report_ok('class-level wait_all_until()');
		}
	}
	$q->enqueue_simplex('stop');
	$server->join;
	$requestor->join;
#
#	make sure no one else is listening on our queue
#
	$q = Thread::Queue::Duplex->new(ListenerRequired => 1);
#
#	test max pending
#
	$q->set_max_pending(5);
	$server = threads->new(\&run_dq, $q);
	$q->wait_for_listener();
	my @ids = ();
	push @ids, $q->enqueue('wait', 5);
	sleep 1;
#
#	queue up several, then see if we block
#
	push @ids, $q->enqueue('foo', 'bar');
	push @ids, $q->enqueue_urgent('foo', 'bar');
	$q->enqueue_simplex_urgent('foo', 'bar');
	$q->enqueue_simplex('foo', 'bar');
	push @ids, $q->enqueue_urgent('foo', 'bar');
#
#	keep time, we should block at this point
#
	my $started = time();
	push @ids, $q->enqueue('foo', 'bar');
	(time() - $started > 1) ?
		report_ok('max_pending') :
		report_fail('max_pending');
#
#	consume all our responses
#
	$q->wait_all(@ids);
#
#	test mark
#
	my $failed = undef;
	my $id1 = $q->enqueue('wait', 3);
	$q->mark($id1, 'CANCEL');
	unless ($q->get_mark($id1) eq 'CANCEL') {
		$failed = 1;
	}
	else {
		sleep 3;	# give thread time to process both
		$result = $q->wait($id1);
		$failed = 1
			unless ($result->[0] eq 'CANCEL');
	}
	$failed ?
		report_fail('mark') :
		report_ok('mark');

	$q->enqueue_simplex('stop');
	$server->join;
#
#	test dequeue_urgent
#
	$server = threads->new(\&run_urgent, $q);
	$q->wait_for_listener();
	$id1 = $q->enqueue('bar', 'foo');
	my $id2 = $q->enqueue_urgent('foo', 'bar');
	sleep 3;	# give thread time to process both
	$result = $q->wait_any($id1, $id2);
	$failed = undef;
	foreach (keys %$result) {
		$failed = 1, last unless ($_ == $id2);
	}
	$failed ?
		report_fail('dequeue_urgent') :
		report_ok('dequeue_urgent');

	$q->enqueue_simplex_urgent('stop');
	$server->join;

$testno--;
$loaded = 1;

