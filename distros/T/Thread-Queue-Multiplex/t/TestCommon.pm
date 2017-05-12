package TestCommon;

use Exporter;
use base('Exporter');
@EXPORT = qw(report_result);

use threads;
use threads::shared;
use Thread::Queue::Multiplex;
use Qable;
use SharedQable;

use strict;
use warnings;

our $srvtype = 'init';

our $testno = 1;

sub has_all_subs {
	my $results = shift;
	my $subs = shift;

	$subs = [ keys %$results ] unless ref $subs;

	foreach my $id (@$subs) {
		return undef
			unless exists $results->{$id};
		my $result = $results->{$id};
		return undef unless (scalar @$result == scalar @_);
		foreach (0..$#$result) {
			return undef
				if (ref $_[$_]) &&
					((! ref $result->[$_]) ||
						(ref $_[$_] ne ref $result->[$_]));

			return undef
				unless (ref $_[$_]) || ($result->[$_] eq $_[$_]);
		}
	}
#
#	validate any result values for each sub
#
	return 1;
}

sub report_result {
	my ($result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $testno # skip $testmsg for $srvtype\n" :
			"ok $testno # $testmsg $okmsg for $srvtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $testno # $testmsg $notokmsg for $srvtype\n";
	}
	$testno++;
}
#
#	test normal dequeue method
#
sub run_dq {
	my ($subid, $q) = @_;

	$q->subscribe($subid);
	while (1) {
		my $left = $q->pending;

		my $req = $q->dequeue;
		my $id = shift @$req;

#print STDERR threads->self()->tid(), " run_dq dq'd ", ($id || 'simplex'), " : $$req[0]\n";

		if ($req->[0] eq 'stop') {
			$q->respond($id, 'stopped');
			$q->unsubscribe();
			last;
		}

		if ($req->[0] eq 'wait') {
			sleep($req->[1]);
		}
		my $canceled;
		if ($req->[0] eq 'wait cancel') {
			sleep($req->[1]);
			$canceled = 1;
		}

		my $frap = ($req->[0] eq 'frap');
		if ($req->[1] && ref $req->[1] && (ref $req->[1] eq 'SharedQable')) {
			$req->[1]->set_value();
		}
#
#	ignore simplex msgs
#
		next
			unless $id;

#print STDERR threads->self()->tid(), " run_dq responding to $id\n";
		$q->marked($id) ?
			$q->respond($id, $q->get_mark($id)) :
			$q->respond($id, @$req);
#print STDERR threads->self()->tid(), " Respond to frap\n" if $frap;
#print STDERR threads->self()->tid(), " Respond to cancel\n" if $canceled;
	}
}
#
#	test nonblocking dequeue method
#
sub run_nb {
	my ($subid, $q) = @_;

	$q->subscribe($subid);
	while (1) {
		my $req = $q->dequeue_nb;

		sleep 1, next
			unless $req;

#print "run_nb dq'd\n";
		my $id = shift @$req;

		$q->respond($id, 'stopped'),
		$q->unsubscribe(),
#		print STDERR "nb stopping\n" and
		last
			if ($req->[0] eq 'stop');

#print STDERR join(', ', @$req), "\n";
		sleep($req->[1])
			if ($req->[0] eq 'wait');

		my $canceled;
		if ($req->[0] eq 'wait cancel') {
			sleep($req->[1]);
			$canceled = 1;
		}
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
	my ($subid, $q) = @_;

	my $timeout = 2;
	$q->subscribe($subid);
	while (1) {

		my $req = $q->dequeue_until($timeout);
		sleep 1, next
			unless $req;

#print "run_until dq'd\n";
		my $id = shift @$req;

		$q->respond($id, 'stopped'),
		$q->unsubscribe(),
		last
			if ($req->[0] eq 'stop');

		sleep($req->[1])
			if ($req->[0] eq 'wait');
		my $canceled;
		if ($req->[0] eq 'wait cancel') {
			sleep($req->[1]);
			$canceled = 1;
		}
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

	$q->wait_for_subscribers(1);

	while (1) {
		my $id = $q->publish('request');
		my $resp = $q->wait($id);

		($resp) = values %$resp;
#		print STDERR "requestor got ", (ref $resp ? $resp->[0] : $resp), "\n";

#		print STDERR "requestor stopping\n" and
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

	$q->subscribe();
	while (1) {
		my $req = $q->dequeue_urgent;

		sleep 1, next
			unless $req;

#print "run_urgent dq'd\n";
		my $id = shift @$req;

		$q->respond($id, 'stopped'),
		$q->unsubscribe(),
		last
			if ($req->[0] eq 'stop');

		sleep($req->[1])
			if ($req->[0] eq 'wait');
		my $canceled;
		if ($req->[0] eq 'wait cancel') {
			sleep($req->[1]);
			$canceled = 1;
		}
#
#	ignore simplex msgs
#
		$q->respond($id, @$req)
			if $id;
	}
}

sub run_test {
	my ($class, $start, $srvcount) = @_;
#
#	create queue
#	spawn server thread
#	execute various requests
#	verify responses
#
#	test constructor
#
	my $q = Thread::Queue::Multiplex->new(ListenerRequired => 1);

	report_result(defined($q), 'create queue');
#
#	test different kinds of dequeue
#
	my @servers = (\&run_dq, \&run_nb, \&run_until);
	my @subIDs = ('run_dq', 'run_nb', 'run_until');
	my @types = ('normal', 'nonblock', 'timed');

	my ($result, $id, $server);

	my $qable = Qable->new();
	my $sharedqable = SharedQable->new();

	foreach ($start..$#servers) {
#
#	create subscriber threads
#
		my @subs = ();
		foreach my $i (1..$srvcount) {
			push @subs, threads->new($servers[$_], $subIDs[$_] . "_$i", $q);
		}
		$srvtype = $types[$_];
#
#	wait for all subscribers
#
		report_result($q->wait_for_subscribers($srvcount), 'wait_for_subscribers()');
#
#	test get_subscribers
#
		my @subids = $q->get_subscribers();
		report_result((@subids && (scalar @subids == $srvcount)), 'get_subscribers()');

####################################################################
#
#	BEGIN PUBLISH TESTS
#
####################################################################
#
#	test publish_simplex
#
		$id = $q->publish_simplex('foo', 'bar');
		report_result(defined($id), 'publish_simplex()');
#
#	test publish
#
		$id = $q->publish('foo', 'bar');
		report_result(defined($id), 'publish()');
#
#	test ready(); don't care about outcome
#	(prolly need eval here)
#
		$result = $q->ready($id);
		report_result(1, 'ready()');
#
#	test wait()
#
		$result = $q->wait($id);
		report_result((defined($result) && has_all_subs($result, \@subids, 'foo', 'bar')),
			'wait()');
#
#	test dequeue_response
#
		$id = $q->publish('foo', 'bar');
		$result = $q->dequeue_response($id);
		report_result((defined($result) && has_all_subs($result, \@subids, 'foo', 'bar')),
			'dequeue_response()');
#
#	test Queueable publish
#
		$id = $q->publish('foo', $qable);
		report_result(defined($id), 'publish() Queueable');

		$result = $q->wait($id);
		report_result((defined($result) && has_all_subs($result, \@subids, 'foo', $qable)),
			'wait() Queueable');
#
#	test wait_until, publish_urgent
#
		$id = $q->publish('wait', 3);
		my $id1 = $q->publish('foo', 'bar');
		$result = $q->wait_until($id, 1);
		report_result((!defined($result)), 'wait_until() expires');

		my $id2 = $q->publish_urgent('urgent', 'entry');
#
#	should get wait reply here
#
		$result = $q->wait_until($id, 5);
		report_result((defined($result) && has_all_subs($result, \@subids, 'wait', 3)), 'wait_until()');
#
#	should get urgent reply here
#
		$result = $q->wait($id2);
		report_result((defined($result) && has_all_subs($result, \@subids, 'urgent', 'entry')), 'publish_urgent()');
#
#	should get normal reply here
#
		$result = $q->wait($id1);
		report_result((defined($result) && has_all_subs($result, \@subids, 'foo', 'bar')),  'publish()');
#
#	test wait_any: need to queue up several
#
		my %ids = ();

		map { $ids{$q->publish('foo', 'bar')} = 1; } (1..10);
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
		report_result((!$failed), 'wait_any()');
#
#	test wait_any_until
#
		%ids = ();

		$ids{$q->publish('wait', '3')} = 1;
		map { $ids{$q->publish('foo', 'bar')} = 1; } (2..10);
		$failed = undef;

		$result = $q->wait_any_until(1, keys %ids);
		if ($result) {
			report_result(undef, 'wait_any_until()');
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
			report_result((!$failed), 'wait_any_until()');
		}
#
#	test wait_all
#
		%ids = ();
		map { $ids{$q->publish('foo', 'bar')} = 1; } (1..10);
#
#	test available()
#
		sleep 2;	# SMP seems to need a bit more time
		my @avail = $q->available;
		report_result((scalar @avail), 'available (array)');

		$id = $q->available;
		report_result($id, 'available (scalar)');

		$id = keys %ids;
		@avail = $q->available($id);
		report_result((scalar @avail), 'available (id)');
#
#	make sure all ids respond
#
		$result = $q->wait_all(keys %ids);
		unless (defined($result) &&
			(ref $result) &&
			(ref $result eq 'HASH') &&
			(scalar keys %ids == scalar keys %$result)) {
			report_result(undef, 'wait_all()');
		}
		else {
			map { $failed = 1 unless delete $ids{$_}; } keys %$result;
			report_result((!($failed || scalar %ids)), 'wait_all()');
		}
#
#	test wait_all_until
#
		%ids = ();
		map { $ids{$q->publish('wait', '1')} = 1; } (1..10);
#
#	make sure all ids respond
#
		$result = $q->wait_all_until(1, keys %ids);
		if (defined($result)) {
			report_result(undef, 'wait_all_until()');
		}
		else {
	# may need a warning print here...
			$result = $q->wait_all_until(20, keys %ids);
			map { $failed = 1 unless delete $ids{$_}; } keys %$result;
			report_result((!($failed || scalar keys %ids)), 'wait_all_until()');
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
		$id = $q->publish('wait', 5);
		$id1 = $q->publish('foo', 'bar');
		$result = $q->wait_until($id, 3);
		$q->cancel($id1);
		report_result((!$q->pending),'cancel()');
		$result = $q->wait($id);
#
#	do same, but add multiple and cancel all
#
		$id = $q->publish('wait', 5);
		$id1 = $q->publish('first', 'bar');
		$id2 = $q->publish('second', 'bar');
		$result = $q->wait_until($id, 1);
		$q->cancel_all();
#print "Cancel all: pending :", $q->pending, " avail ", $q->available, "\n";
		report_result((!($q->pending || $q->available)), 'cancel_all()');

####################################################################
#
#	END PUBLISH TESTS
#
####################################################################
####################################################################
#
#	BEGIN ENQUEUE TESTS
#
####################################################################
#
#	create subset of subs
#
		if ((scalar @subids) > 1) {
			my $subset = (scalar @subids) >> 1;
			@subids = @subids[1..$subset];
		}
#
#	test enqueue_simplex
#
		$id = $q->enqueue_simplex(\@subids, 'foo', 'bar');
		report_result(defined($id), 'enqueue_simplex()');
#
#	test enqueue
#
		$id = $q->enqueue(\@subids, 'foo', 'bar');
		report_result(defined($id), 'enqueue()');
#
#	test ready(); don't care about outcome
#	(prolly need eval here)
#
		$result = $q->ready($id);
		report_result(1, 'ready()');
#
#	test wait()
#
		$result = $q->wait($id);
		report_result(
			(defined($result) && has_all_subs($result, \@subids, 'foo', 'bar')), 'wait()');
#
#	test dequeue_response
#
		$id = $q->enqueue(\@subids, 'frap', 'bar');
#print STDERR "Sub ids are ", join(', ', @subids), "\n";
		$result = $q->dequeue_response($id);
#print STDERR "result is $result\n";
		report_result(
			(defined($result) && has_all_subs($result, \@subids, 'frap', 'bar')), 'dequeue_response()');
#
#	test TQM_FIRST_ONLY
#
		$id = $q->enqueue(-1, 'foo', 'bar');
		$result = $q->dequeue_response($id);
		report_result(
			(defined($result) && has_all_subs($result, -1, 'foo', 'bar')), 'FIRST_ONLY');
#
#	test Queueable enqueue
#
		$id = $q->enqueue(\@subids, 'foo', $qable);
		report_result(defined($id), 'enqueue() Queueable');

		$result = $q->wait($id);
		report_result(
			(defined($result) && has_all_subs($result, \@subids, 'foo', $qable)), 'wait() Queueable()');
#
#	test wait_until, enqueue_urgent
#
		$id = $q->enqueue(\@subids, 'wait', 3);
		$id1 = $q->enqueue(\@subids, 'foo', 'bar');
		$result = $q->wait_until($id, 1);
		report_result((!defined($result)), 'wait_until() expires');

		$id2 = $q->enqueue_urgent(\@subids, 'urgent', 'entry');
#
#	should get wait reply here
#
		$result = $q->wait_until($id, 5);
		report_result(
			(defined($result) && has_all_subs($result, \@subids, 'wait', 3)), 'wait_until()');
#
#	should get urgent reply here
#
		$result = $q->wait($id2);
		report_result(
			(defined($result) && has_all_subs($result, \@subids, 'urgent', 'entry')), 'enqueue_urgent()');
#
#	should get normal reply here
#
		$result = $q->wait($id1);
		report_result(
			(defined($result) && has_all_subs($result, \@subids, 'foo', 'bar')), 'enqueue()');
#
#	test wait_any: need to queue up several
#
		%ids = ();

		map { $ids{$q->enqueue(\@subids, 'foo', 'bar')} = 1; } (1..10);
#
#	repeat here until all ids respond
#
		$failed = undef;
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
		report_result((!$failed), 'wait_any()');
#
#	test wait_any_until
#
		%ids = ();

		$ids{$q->enqueue(\@subids, 'wait', '3')} = 1;
		map { $ids{$q->enqueue(\@subids, 'foo', 'bar')} = 1; } (2..10);
		$failed = undef;

		$result = $q->wait_any_until(1, keys %ids);
		if ($result) {
			report_result(undef, 'wait_any_until()');
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
			report_result((!$failed), 'wait_any_until()');
		}
#
#	test wait_all
#
		%ids = ();
		map { $ids{$q->enqueue(\@subids, 'foo', 'bar')} = 1; } (1..10);
#
#	test available()
#
		sleep 2;	# SMP seems to need a bit more time
		@avail = $q->available;
		report_result((scalar @avail), 'available (array)');

		$id = $q->available;
		report_result($id, 'available (scalar)');

		$id = keys %ids;
		@avail = $q->available($id);
		report_result((scalar @avail), 'available (id)');
#
#	make sure all ids respond
#
		$result = $q->wait_all(keys %ids);
		unless (defined($result) &&
			(ref $result) &&
			(ref $result eq 'HASH') &&
			(scalar keys %ids == scalar keys %$result)) {
			report_result(undef, 'wait_all()');
		}
		else {
			map { $failed = 1 unless delete $ids{$_}; } keys %$result;
			report_result((!($failed || scalar %ids)), 'wait_all()');
		}
#
#	test wait_all_until
#
		%ids = ();
		map { $ids{$q->enqueue(\@subids, 'wait', '1')} = 1; } (1..10);
#
#	make sure all ids respond
#
		$result = $q->wait_all_until(1, keys %ids);
		if (defined($result)) {
			report_result(undef, 'wait_all_until()');
		}
		else {
	# may need a warning print here...
			$result = $q->wait_all_until(20, keys %ids);
			map { $failed = 1 unless delete $ids{$_}; } keys %$result;
			report_result((!$failed || scalar keys %ids), 'wait_all_until()');
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
		$id = $q->enqueue(\@subids, 'wait cancel', 5);
		$id1 = $q->enqueue(\@subids, 'foo', 'bar');
		$result = $q->wait_until($id, 2);
		$q->cancel($id1);
		$result = $q->wait($id) unless $result;
		my $pend = $q->pending;
#print "Cancel: after pending :", $pend, "\n";
#print "Cancel: request incomplete\n" unless $result;
		report_result(($pend == 0), 'cancel()');
#print "Cancel: after pending :", $q->pending, "\n";
#
#	do same, but add multiple and cancel all
#
		$id = $q->enqueue(\@subids, 'wait', 5);
		$id1 = $q->enqueue(\@subids, 'first', 'bar');
		$id2 = $q->enqueue(\@subids, 'second', 'bar');
		$result = $q->wait_until($id, 1);
		$q->cancel_all();
#print "Cancel all: pending :", $q->pending, " avail ", $q->available, "\n";
		report_result((!($q->pending || $q->available)), 'cancel_all()');

####################################################################
#
#	END ENQUEUE TESTS
#
####################################################################

#
#	kill the thread; also tests urgent i/f
#
		$id = $q->publish_urgent('stop');
		report_result($id, 'publish_urgent()');
#		print STDERR "Waiting for $id\n";
		$result = $q->wait($id);

#		print STDERR "Joining \n";
		$_->join
			foreach (@subs);
#
#	test publish wo/ a subscriber
#
		report_result((!$q->publish('no subscriber')), 'publish() wo/ subscriber');

	}	#end foreach server method
#
#	now test the class-level waits:
#	create an add'l queue
#	create a subscriber thread w/ old queue
#	create requestor thread w/ new queue
#
	my $newq = Thread::Queue::Multiplex->new(ListenerRequired => 1);
	my @subs = ();
	push @subs, threads->new($servers[0], $subIDs[0] . "_$_", $q)
		foreach (1..$srvcount);

	$srvtype = $types[0];
	$q->wait_for_subscribers($srvcount);
	my @subids = $q->get_subscribers();
#
#	test shared Queueable publish
#
	$id = $q->publish('foo', $sharedqable);
	report_result(defined($id), 'publish() shared Queueable');

	$result = $q->wait($id);
	report_result(
		(defined($result) && has_all_subs($result, \@subids, 'foo', $sharedqable)),
		'wait() shared Queueable');

	my $requestor = threads->new(\&run_requestor, $newq);
	$newq->subscribe('main_thread');
	my @qs = ();
#
#	post request to subscriber
#	wait on both queues
#
	$id = $q->publish('wait', 3);
	print "ID is undef!!!\n" unless defined($id);
	@qs = Thread::Queue::Multiplex->wait_any([$q, $id], [$newq]);
	unless (scalar @qs) {
		report_result(undef, 'class-level wait_any()');
	}
	else {
#
#	should get the newq only here...
#
		unless ((scalar @qs == 1) && ($qs[0] eq $newq)) {
			report_result(undef, 'class-level wait_any()');
		}
		else {
			my $req = $newq->dequeue();
			$newq->respond(shift @$req, 'ok');
		}
#
#	wait for other queue
#
		my $resp = $q->wait($id);
		report_result(1, 'class-level wait_any()');
	}
#
#	now timed wait_any
#
	$id = $q->publish('wait', 3);
	@qs = Thread::Queue::Multiplex->wait_any_until(3, [$q, $id], [$newq]);
	unless (scalar @qs) {
		report_result(undef, 'class-level wait_any_until()');
	}
	else {
#
#	should get the newq only here...
#
		unless ((scalar @qs == 1) && ($qs[0] eq $newq)) {
			report_result(undef, 'class-level wait_any_until()');
		}
		else {
			my $req = $newq->dequeue();
			$newq->respond(shift @$req, 'ok');
		}
#
#	wait for other queue
#
		my $resp = $q->wait($id);
		report_result(1, 'class-level wait_any_until()');
	}
#
#	now wait_all
#
	$id = $q->publish('wait', 3);
	@qs = Thread::Queue::Multiplex->wait_all([$q, $id], [$newq]);
	unless (scalar @qs == 2) {
		report_result(undef, 'class-level wait_all()');
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
		report_result(1, 'class-level wait_all()');
	}
#
#	now timed wait_all
#
	$id = $q->publish('wait', 3);
	@qs = Thread::Queue::Multiplex->wait_all_until(1, [$q, $id], [$newq]);
#
#	shouldn't get anything first time thru
#
	if (@qs) {
#	print STDERR "Got unexpected queued elements\n";
		report_result(undef, 'class-level wait_all_until()');
	}
	else {
		@qs = Thread::Queue::Multiplex->wait_all_until(5, [$q, $id], [$newq]);
		unless (scalar @qs == 2) {
#	print STDERR "Got ", (scalar @qs), " expected 2 elements\n";
			report_result(undef, 'class-level wait_all_until()');
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
			report_result(1, 'class-level wait_all_until()');
		}
	}
	$q->publish_simplex('stop');
	$_->join
		foreach (@subs);
	$requestor->join;
#
#	make sure no one else is subscribed on our queue
#
	$q = Thread::Queue::Multiplex->new(ListenerRequired => 1);
#
#	test max pending
#
	$q->set_max_pending(5);
	$server = threads->new(\&run_dq, 'run_dq_20', $q);
	$q->wait_for_subscribers(1);
	my @ids = ();
	push @ids, $q->publish('wait', 5);
	sleep 2;	# SMP seems to need a bit more time
#
#	queue up several, then see if we block
#
	push @ids, $q->publish('foo', 'bar');
	push @ids, $q->publish_urgent('foo', 'bar');
	$q->publish_simplex_urgent('foo', 'bar');
	$q->publish_simplex('foo', 'bar');
	push @ids, $q->publish_urgent('foo', 'bar');
#
#	keep time, we should block at this point
#
	my $started = time();
	push @ids, $q->publish('foo', 'bar');
	report_result((time() - $started > 1), 'max_pending');
#
#	consume all our responses
#
	$q->wait_all(@ids);
#
#	test mark
#
	my $failed = undef;
	my $id1 = $q->publish('wait', 3);
	$q->mark($id1, 'CANCEL');
	unless ($q->get_mark($id1) eq 'CANCEL') {
		$failed = 1;
	}
	else {
		sleep 3;	# give thread time to process both
		$result = $q->wait($id1);
		($result) = values %$result;
		$failed = 1
			unless ($result->[0] eq 'CANCEL');
	}
	report_result((!$failed), 'mark');

	$q->publish_simplex('stop');
	$server->join;
#
#	test dequeue_urgent
#
	$server = threads->new(\&run_urgent, $q);
	$q->wait_for_subscribers(1);
	$id1 = $q->publish('bar', 'foo');
	my $id2 = $q->publish_urgent('foo', 'bar');
	sleep 3;	# give thread time to process both
	$result = $q->wait_any($id1, $id2);
	$failed = undef;
	foreach (keys %$result) {
		$failed = 1, last unless ($_ == $id2);
	}
	report_result((!$failed), 'dequeue_urgent');

	$q->publish_simplex_urgent('stop');
	$server->join;

	$testno--;
	return $testno;
}
