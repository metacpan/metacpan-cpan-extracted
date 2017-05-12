package Thread::Queue::Multiplex;
#
# Copyright(C) 2005, 2006, Dean Arnold, Presicient Corp., USA
#
# Permission is granted to use this software according to the
# terms of the Perl Artistic License, as
# specified in the Perl README file.
#
#	A subclass of Thread::Queue::Duplex to support
#	publish/subscribe communications for threads
#
require 5.008;

use threads;
use threads::shared;
use Thread::Queue::Queueable;
use Thread::Queue::Duplex;

use base qw(Thread::Queue::Duplex);

use strict;
use warnings;

our $VERSION = '0.92';

=head1 NAME

Thread::Queue::Multiplex (I<aka> TQM) - thread-safe publish/subscribe queue

=begin html

<a href='http://www.presicient.com/tqm/Thread-Queue-Multiplex-0.91.tar.gz'>Thread-Queue-Multiplex-0.91.tar.gz</a>

=end html

=head1 SYNOPSIS

	use Thread::Queue::Multiplex;
	#
	#	create new queue, limiting the max pending requests
	#	to 20
	#
	my $tqm = Thread::Queue::Multiplex->new(MaxPending => 20);
	#
	#	register as a subscriber
	#
	$tqm->subscribe('myID');
	#
	#	unregister as a subscriber
	#
	$tqm->unsubscribe();
	#
	#	wait for $count subscribers to register
	#
	$tqm->wait_for_subscribers($count, $timeout);
	#
	#	get the list of current subscribers ID's
	#
	my @subids = $tqm->get_subscribers();
	#
	#	change the max pending limit
	#
	$tqm->set_max_pending($limit);
	#
	#	enqueue elements, returning a unique queue ID
	#	(used in the client)
	#
	my $id = $tqm->publish("foo", "bar");
	#
	#	publish elements, and wait for a response
	#	(used in the client)
	#
	my $resp = $tqm->publish_and_wait("foo", "bar");
	#
	#	publish elements, and wait for a response
	#	until $timeout secs (used in the client)
	#
	my $resp = $tqm->publish_and_wait_until($timeout, "foo", "bar");
	#
	#	publish elements at head of queue, returning a
	#	unique queue ID (used in the client)
	#
	my $id = $tqm->publish_urgent("foo", "bar");
	#
	#	publish elements at head of queue and wait for response
	#
	my $resp = $tqm->publish_urgent_and_wait("foo", "bar");
	#
	#	publish elements at head of queue and wait for
	#	response until $timeout secs
	#
	my $resp = $tqm->publish_urgent_and_wait_until($timeout, "foo", "bar");
	#
	#	publish elements for simplex operation (no response)
	#	returning the queue object
	#
	$tqm->publish_simplex("foo", "bar");

	$tqm->publish_simplex_urgent("foo", "bar");
	#
	#########################################################
	#
	#	subscribers use the existing TQD dequeue() methods
	#
	#######################################################
	#
	#	modified versions of the TQD base enqueue methods
	#	to support directed messaging to a single subscriber
	#	or group of subscribers
	#
	#######################################################
	#
	#	enqueue elements to a specific subscriber, returning
	#	a unique queue ID (used in the client)
	#
	my $id = $tqm->enqueue($subID, "foo", "bar");
	#
	#	enqueue elements to 2 subscribers, and wait for a response
	#	(used in the client)
	#
	my $resp = $tqm->enqueue_and_wait([ $subID1, $subID2 ], "foo", "bar");
	#
	#	enqueue elements, and wait for a response
	#	until $timeout secs (used in the client)
	#
	my $resp = $tqm->enqueue_and_wait_until($subID, $timeout, "foo", "bar");
	#
	#	SEE Thread::Queue::Duplex for the various publisher enqueue()
	#	and wait() methods,
	#	and the subscriber dequeue() methods
	#

=head1 DESCRIPTION

A subclass of L<Thread::Queue::Duplex> I<aka> B<TQD> which implements a
"publish and subscribe" communications model for threads. Subscribers
register with the queue, which registers either the provided subscriber ID,
or, if no ID is provided, 1 plus the TID of the subscriber's thread,
as a subscriber ID. As the publisher publishes
messages to the queue, each subscriber receives
a copy of the message. If the publication is B<not> simplex, the publisher
expects all subscribers to read and respond to the message; otherwise, the
publisher simply continues its processing. Thread::Queue::Multiplex
provides C<publish()> method counterparts for all the L<Thread::Queue::Duplex>
C<enqueue()> methods, e.g., C<publish_simplex(), publish_urgent(),
publish_and_wait(), publish_and_wait_until()>, etc.

Subscribers receive and reply to messages using the existing TQD
dequeue() and respond() methods. In addition, modified versions of
the enqueue() methods are provided to publishers to permit directing
a message to a single subscriber, or subset of subscribers, by specifying
the scalar subscriber ID (for single subscriber messages), or
an arrayref of unique subscriber ID's (for multi-subscriber messages).

C<Thread::Queue::Multiplex> subclass overrides some of the internal behavior
of L<Thread::Queue::Duplex> by

=over 4

=item *

adding a shared hash to hold the list of unique subscriber ID's
(provided either explicitly with C<subscribe()>, or derived from
1 + L<threads>C<-E<gt>self()-E<gt>tid()> when the
subscriber C<subscribe()>s) mapped to a threads::shared
array to hold ID's of messages published to the subscriber.
(B<Note:> tid() + 1 is used in order to avoid an ID of zero
for the root thread).

=item *

adding a shared hash to hold the list of message ID's
mapped to a threads::shared array to containing
C<[message ID, flags, refcount, @params]>, where
C<flags> indicates the urgent and/or simplex status
of the request, and C<refcount> indicates the number
of subscribers assigned to the request. A special C<refcount>
value of -1 indicates that only the first subscriber to
retrieve/process the request should respond (to mimic the
behavior of L<Thread::Queueu::Duplex>), which is
specified by the publisher using any of the C<enqueue>
methods with a subscriber ID of -1.

=item *

adding a shared hash to hold the list of message ID's
mapped to a L<threads::shared> hash containing
a reference count of subscribers for the message,
and a map of subscriber IDs to their responses.
This "pending response" hash is used to accumulate
all subscriber responses; when the reference count of
a message is zero, the hash of responses is posted to
the final response message mapping hash.

=item *

adding a shared hash to hold the map of thread ID's to
subscriber ID's. B<Note:> Each thread can have only a single
subscriber.

=item *

changing the message mapping hash to map a unique message ID
to a hash of unique subscriber ID's, mapped to their response (if any),
i.e.,

	$msg_map = {
		$msgid => {
			$subID1 => $subID1_response,
			$subID2 => $subID2_response,
			etc.
		}
	}

=item *

when the publisher dequeues the response to a message, it receives
a copy of the subscriber mapping hash, and is responsible for iterating
over the hash to read each subscriber's results

=back

A normal processing sequence for Thread::Queue::Multiplex might be:

	#
	#	Thread A (the client):
	#
		...marshal parameters for a coroutine...
		my $id = $tqm->publish('function_name', \@paramlist);
		my $results = $tqm->dequeue_response($id);
		while (($subID, $subresult) = each %$results) {
		...process $results...
		}
	#
	#	Thread B (a subscriber):
	#
		while (1) {
			my $call = $tqm->dequeue;
			my ($id, $func, @params) = @$call;
			$tqm->respond($id, $self->$func(@params));
		}

=head1 FUNCTIONS AND METHODS

=over 4

=item $tqm = B<Thread::Queue::Multiplex-E<gt>new>([MaxPending => $limit])

Constructor. Creates a new empty queue.
If the C<MaxPending> value is a non-zero value, the number
of pending requests will be limited to C<$limit>, and any further
attempt to queue a request will block until the pending count
drops below C<$limit>. This limit may be applied or modified later
via the C<set_max_pending()> method (see below).

=item B<subscribe( >I<[ $subID ]>B< )> I<aka> B<listen()>

Subscribe to the queue. The listen() alias is provided for
compatibility with TQD apps. If C<$subID> is not provided, 1 plus
the current thread's TID is used as the subscriber ID.
Only a single subscriber per thread is permitted; undef will
be returned if the current thread already has a subscriber.

=item B<unsubscribe()> I<aka> B<ignore()>

Unsubscribe from the queue. The ignore() alias is provided for
compatibility with TQD apps. Note the subscriber for the current
thread is unsubscribed. I<Unsubscribing another thread is not
currently supported.>

=item @subIDs = $tqm->B<get_subscribers()>

Returns the current list of subscriber IDs.

=item $msgID = $tqm->B<publish(@request)>

L<enqueue>()s the C<@request> to all subscribers.

=item $results = $tqm->B<publish_and_wait(@request)>

Same as L<publish>, except that it waits for and returns
the response hash, rather than returning
immediately with the request ID.

=item $results = $tqm->B<publish_and_wait_until($timeout, @request)>

Same as L<publish>, except that it waits up to $timeout
seconds for all subscribers to respond, and returns the
response hash, rather
than returning immediately with the request ID. If some, but not all,
subscribers respond within the timeout, the responses are discarded.

=item $msgID = $tqm->B<publish_urgent(@request)>

Same as L<publish>, but adds the element to head of queue, rather
than tail.

=item $results = $tqm->B<publish_urgent_and_wait(@request)>

Same as L<publish_and_wait>, but adds the element to head of queue, rather
than tail.

=item $results = $tqm->B<publish_urgent_and_wait_until($timeout, @request)>

Same as L<publish_and_wait_until>, but adds the element to head of queue, rather
than tail.

=item $msgID = $tqm->B<publish_simplex(@request)>

Same as L<publish>, but does not allocate an identifier, nor
expect a response.

=item $msgID = $tqm->B<publish_simplex_urgent(@request)>

Same as L<publish_simplex>, but adds the element to head of queue,
rather than tail.

=item $count = $tqm->B<pending()>

Returns the number of items still in the queue.
B<Note> that, for subscribers, the returned value
is the number of requests published to the individual subscriber,
which may be less than the total number of pending requests,
due to directed C<enqueue> requests. Also, for subscribers,
the number may include requests which have been cancelled,
but not yet processed/discarded by the subscriber.

=back

The following TQD methods are overloaded by TQM to support
directed requests by adding either a single scalar subscriber
ID, or an arrayref of multiple subscriber IDs, as the first
parameter:

=over 4

=item $msgID = $tqm->enqueue( $subID, @request)

=item $msgID = $tqm->enqueue( [ @subIDs ], @request)

=item $msgID = $tqm->enqueue_simplex( $subID, @request)

=item $msgID = $tqm->enqueue_simplex( [ @subIDs ], @request)

=item $msgID = $tqm->enqueue_urgent( $subID, @request)

=item $msgID = $tqm->enqueue_urgent( [ @subIDs ], @request)

=item $msgID = $tqm->enqueue_simplex_urgent( $subID, @request)

=item $msgID = $tqm->enqueue_simplex_urgent( [ @subIDs ], @request)

=item $result = $tqm->enqueue_and_wait( $subID, @request)

=item $result = $tqm->enqueue_and_wait( [ @subIDs ], @request)

=item $result = $tqm->enqueue_urgent_and_wait( $subID, @request)

=item $result = $tqm->enqueue_urgent_and_wait( [ @subIDs ], @request)

=item $result = $tqm->enqueue_and_wait_until( $subID, $timeout, @request)

=item $result = $tqm->enqueue_and_wait_until( [ @subIDs ], $timeout, @request)

=item $result = $tqm->enqueue_urgent_and_wait_until( $subID, $timeout, @request)

=item $result = $tqm->enqueue_urgent_and_wait_until( [ @subIDs ], $timeout, @request)

=back

=head1 CAVEATS

If any subscriber thread dies, then the publisher may hang
on any of the blocking publish calls, or the wait()/dequeue_response().
A future update may support occasional scans and forced
unsubscribe() for dead threads.

=head1 SEE ALSO

L<Thread::Queue::Duplex>
L<Thread::Queue::Queueable>,
L<threads>
L<threads::shared>
L<Thread::Queue>

=head1 AUTHOR, COPYRIGHT, & LICENSE

Dean Arnold, Presicient Corp. L<darnold@presicient.com>

Copyright(C) 2006, Presicient Corp., USA

Licensed under the Academic Free License version 2.1, as specified in the
License.txt file included in this software package, or at OpenSource.org
L<http://www.opensource.org/licenses/afl-2.1.php>.

=cut

#
#	global semaphore used for class-level wait()
#	notification
#
use Thread::Queue::Duplex;
use Thread::Queue::Duplex qw(:tqd_codes $tqd_global_lock);
use base qw(Thread::Queue::Duplex);
#
#	import the following member names from TQD:
#
#use constant TQD_Q => 0;
#use constant TQD_MAP => 1;
#use constant TQD_IDGEN => 2;
#use constant TQD_LISTENERS => 3;
#use constant TQD_REQUIRE_LISTENER => 4;
#use constant TQD_MAX_PENDING => 5;
#use constant TQD_URGENT_COUNT => 6;
#use constant TQD_MARKS => 7;
#
#	then add our own
#
use constant TQM_SUBSCRIBERS => 8;
use constant TQM_SUB_MAP => 9;
use constant TQM_PENDING_MAP => 10;
use constant TQM_SUB_ID_MAP => 11;
#
#	flags for special msgs
#
use constant TQM_URGENT => 1;
use constant TQM_SIMPLEX => 2;
use constant TQM_URGENT_SIMPLEX => 3;
#
#	when used for subid, indicates only the
#	first sub to see it should process the msg
#	(ie reverts to TQD behavior)
#
use constant TQM_FIRST_ONLY => -1;
#################################################
#
#	The following methods are inherited from TQD:
#	_get_id()
#	_filter_nq()
#	wait_for_listener()
#	set_max_pending()
#	wait()
#	dequeue_response()
#	ready()
#	available()
#	wait_until()
#	wait_any()
#	wait_any_until()
#	wait_all()
#	wait_all_until()
#	mark()
#	unmark()
#	get_mark()
#	marked()
#	_tqd_wait()
#	TQQ curse()/redeem()
#
##################################################
#################################################
#
# !!!NOTE!!!NOTE!!!NOTE!!!NOTE!!!NOTE!!!NOTE!!!NOTE
#
#	always retain this lock order:
#	TQD_Q before TQM_PENDING_MAP
#	TQM_PENDING_MAP before TQD_MAP
#	TQM_MAP before TQD_MARKS
#
#################################################

sub new {
    my $class = shift;

	my $obj = $class->SUPER::new(@_);
	return undef unless $obj;
#
#	map of subids to their msgid queues
#
	my %subscribers : shared = ();
#
#	map of msgids to their pending msg info
#
	my %pendingmsgs : shared = ();
#
#	map of msgids to their pending response info
#
	my %pendingresps : shared = ();
#
#	map of subscriber TIDs to their sub ID
#
	my %subids : shared = ();

	$obj->[TQM_SUBSCRIBERS] = \%subscribers;
	$obj->[TQM_SUB_MAP] = \%pendingmsgs;
	$obj->[TQM_PENDING_MAP] = \%pendingresps;
	$obj->[TQM_SUB_ID_MAP] = \%subids;
    return $obj;
}

sub subscribe {
	my $obj = shift;
	my $tid = threads->self()->tid() + 1;
	my $id = shift || $tid;
	lock(${$obj->[TQD_LISTENERS]});
#
#	we only permit a single subscriber per thread
#
	$@ = 'Thread $tid already subscribed as ' .
		$obj->[TQM_SUB_ID_MAP]{$tid},
	return undef
		if $obj->[TQM_SUB_ID_MAP]{$tid};

	${$obj->[TQD_LISTENERS]}++;
	my @pending_msgs : shared = ();
	$obj->[TQM_SUBSCRIBERS]{$id} = \@pending_msgs;
	$obj->[TQM_SUB_ID_MAP]{$tid} = $id;
	cond_broadcast(${$obj->[TQD_LISTENERS]});
	return $obj;
}

sub unsubscribe {
	my $obj = shift;
	my $id = threads->self()->tid() + 1;
	my $pending;
	{
		lock(${$obj->[TQD_LISTENERS]});
		$@ = "No subscriber in thread $id.",
		return undef
			unless $obj->[TQM_SUB_ID_MAP]{$id};
		$id = delete $obj->[TQM_SUB_ID_MAP]{$id};
		$pending = delete $obj->[TQM_SUBSCRIBERS]{$id};
		${$obj->[TQD_LISTENERS]}--
			if ${$obj->[TQD_LISTENERS]};
	}
	return $obj unless scalar @$pending;

	my @completed = ();
#
#	walk pending requests and remove any reference to ourselves,
#	possibly signalling request completion if we're the only/last
#	subscriber
#	Note we leave pending responses intact
#
	{
		lock(@{$obj->[TQD_Q]});
		foreach (@$pending) {
#
#	need to be careful here due to inconsistent deref behavior of
#	threads::shared
#
			if ($obj->[TQM_SUB_MAP]{$_}) {
				my $entry = $obj->[TQM_SUB_MAP]{$_};
				if ($entry->{_refcnt} && ($entry->{_refcnt} != TQM_FIRST_ONLY)) {
#
#	what should we do about FIRST_ONLY here ?
#	if we're the only sub, then the publisher may get
#	hung...for now, we'll ignore them
#
					$entry->{_refcnt}--;
					push @completed, $_
						unless $entry->{_refcnt};
				}
			}
		}
	}
#
#	we postpone posting completions so we don't constantly
#	lock/unlock ..and possibly deadlock...; this way we
#	can just lock, post all, unlock
#
	$obj->_post_complete(@completed)
		if scalar @completed;

	return $obj;
}
#
#	override listen/ignore to mimic subscribe/unsubscribe
#
sub listen {
	return subscribe(@_);
}

sub ignore {
	return unsubscribe(@_);
}

sub get_subscribers {
	my $obj = shift;
	lock(${$obj->[TQD_LISTENERS]});
	return keys %{$obj->[TQM_SUBSCRIBERS]};
}
#
#	wait until we've got subscribers
#
sub wait_for_subscribers {
	my ($obj, $count, $timeout) = @_;
	my $listeners = $obj->[TQD_LISTENERS];
	lock($$listeners);

	return undef
		if ($timeout && ($timeout < 0));

	if ($timeout) {
		$timeout += time();
		cond_timedwait($$listeners, $timeout)
			while ($$listeners != $count) && ($timeout > time());

		return ($$listeners eq $count) ? $obj : undef;
	}

	cond_wait($$listeners)
		while ($$listeners != $count);
	return ($$listeners == $count) ? $obj : undef;
}
#
#	override lock & load to include subid list
#
sub _lock_load {
	my $obj = shift;
	my $flags = shift || 0;
	my $subs = shift;
#
#	create shared array of params here, leaving
#	the open spot for the subids list
#
	my $msgid = $obj->_get_id;	# always assign ID, even for simplex
#
#	NOTE: we trick _filter_nq into opening up a couple extra
#	slots for us, which we later fill with an Underdog
#	Super Energy Pill, namely, the simplex flag and the refcnt
#
	my $params = Thread::Queue::Duplex::_filter_nq($msgid, undef, @_);
	$params->[1] = $flags;
#
#	Note that sequence is important here;
#	a sub may unsubscribe after we've
#	published to it, but before msg delivery...but
#	the unsubscribe process will purge the sub
#	from any pending msgs. We don't publish
#	to subs that aren't subscribed; since we have
#	to cond_wait until the queue length is under the max,
#	we don't do subs assignment until then (in case
#	some subs unsubscribe while we're cond_waiting)
#
	my $q = $obj->[TQD_Q];
	lock(@$q);
#
#	check current length if we have a limit
#
	while (${$obj->[TQD_MAX_PENDING]} &&
		(${$obj->[TQD_MAX_PENDING]} <= scalar keys %{$obj->[TQM_SUB_MAP]})) {
#		print "pending before: ", scalar @$q, "\n";
		cond_wait(@$q);
#		print "pending after: ", scalar @$q, "\n";
	}

	my $firstonly = (defined($subs) && (! ref $subs) && ($subs == TQM_FIRST_ONLY));
	$subs = (defined($subs) && (! $firstonly)) ?
		[ $subs ] :
		[ keys %{$obj->[TQM_SUBSCRIBERS]} ]
		unless defined($subs) && (ref $subs);

	$params->[2] = $firstonly ? TQM_FIRST_ONLY : scalar @$subs;
	$obj->[TQM_SUB_MAP]{$msgid} = $params;
	unless ($params->[1] & TQM_SIMPLEX) {
#
#	if we need a response, post the prelim
#
		my %pending : shared = (_refcnt => $params->[2]);
		lock(%{$obj->[TQM_PENDING_MAP]});
		$obj->[TQM_PENDING_MAP]{$msgid} = \%pending;
	}
#
#	now post the msgid to every assigned sub's queue
#	at present, we'll use the TQD_Q lock to lock these as well
#
	foreach (@$subs) {
		my $s = $obj->[TQM_SUBSCRIBERS]{$_};
		($flags & TQM_URGENT) ?
		    unshift @$s, $msgid :
		    push @$s, $msgid;
	}
    cond_broadcast @$q;
    return $msgid;
}


###########################
#
#	publish methods:
#	Note the parlor trick: we just alias to the
#	enqueue() methods, but with a funky
#	signature to indicate that all subs
#	should be queued
#	FYI: subscribers registering after we publish,
#	but before the msg is fully consumed, won't get
#	the message
#
sub publish {
    return enqueue(undef, @_);
}

sub publish_urgent {
    return enqueue_urgent(undef, @_);
}
#
#	blocking versions of publish()
#
sub publish_and_wait {
    return enqueue_and_wait(undef, @_);
}

sub publish_and_wait_until {
    return enqueue_and_wait_until(undef, @_);
}

sub publish_urgent_and_wait {
    return enqueue_urgent_and_wait(undef, @_);
}

sub publish_urgent_and_wait_until {
    return enqueue_urgent_and_wait_until(undef, @_);
}
#
#	Simplex versions
#
sub publish_simplex {
    return enqueue_simplex(undef, @_);
}

sub publish_simplex_urgent {
    return enqueue_simplex_urgent(undef, @_);
}
#
#	override of base enqueue methods
#
sub enqueue {
    my $obj = shift;
    my $subs = shift;
#
#	check if its a publish...
#
	($obj, $subs) = ($subs, undef)
		unless defined($obj);

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));
	my $id = _lock_load($obj, undef, $subs, @_);
	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $id;
}

sub enqueue_urgent {
    my $obj = shift;
    my $subs = shift;
#
#	check if its a publish...
#
	($obj, $subs) = ($subs, undef)
		unless defined($obj);

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));
	my $id = _lock_load($obj, TQM_URGENT, $subs, @_);

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $id;
}
#
#	blocking versions of enqueue()
#
sub enqueue_and_wait {
    my $obj = shift;
#
#	check if its a publish...
#
	$obj = shift,
	unshift @_, undef
		unless defined($obj);

	my $id = $obj->enqueue(@_);
	return defined($id) ? $obj->wait($id) : undef;
}

sub enqueue_and_wait_until {
    my $obj = shift;
    my $subs = shift;
	my $timeout = shift;
#
#	check if its a publish...
#
	($obj, $subs) = ($subs, undef)
		unless defined($obj);

	my $id = $obj->enqueue($subs, @_);
	return defined($id) ? $obj->wait_until($id, $timeout) : undef;
}

sub enqueue_urgent_and_wait {
    my $obj = shift;
#
#	check if its a publish...
#
	$obj = shift,
	unshift @_, undef
		unless defined($obj);

	my $id = $obj->enqueue_urgent(@_);
	return defined($id) ? $obj->wait($id) : undef;
}

sub enqueue_urgent_and_wait_until {
    my $obj = shift;
    my $subs = shift;
	my $timeout = shift;
#
#	check if its a publish...
#
	($obj, $subs) = ($subs, undef)
		unless defined($obj);

	my $id = $obj->enqueue_urgent($subs, @_);
	return defined($id) ? $obj->wait_until($id, $timeout) : undef;
}
#
#	Simplex versions
#
sub enqueue_simplex {
    my $obj = shift;
    my $subs = shift;
#
#	check if its a publish...
#
	($obj, $subs) = ($subs, undef)
		unless defined($obj);

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));

	_lock_load($obj, TQM_SIMPLEX, $subs, @_);

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $obj;
}

sub enqueue_simplex_urgent {
    my $obj = shift;
    my $subs = shift;
#
#	check if its a publish...
#
	($obj, $subs) = ($subs, undef)
		unless defined($obj);

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));

	_lock_load($obj, TQM_URGENT_SIMPLEX, $subs, @_);

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $obj;
}

#
#	recover original param list, including reblessing Queueables
#	NOTE: we need to maintain the list until all the subs have
#	consumed it
#
sub _filter_dq {
	my $result = shift;
#
#	keep ID; collapse the rest
#
	my @results = (($result->[1] & TQM_SIMPLEX) ? undef : $result->[0]);
	my $class;
	my $i = 3;

	$class = $result->[$i++],
	push (@results,
		$class ?
		${class}->onDequeue($result->[$i++]) :
		$result->[$i++])
		while ($i < scalar @$result);

    return \@results;
}
#
#	common method for getting the request out of the queue
#
sub _get_request {
	my ($obj, $msgid, $need_urgent) = @_;
#
#	cancelled request (ie map entry has been deleted) ?
#
   	return undef
   		unless exists $obj->[TQM_SUB_MAP]{$msgid};

   	my $request = $obj->[TQM_SUB_MAP]{$msgid};
   	return undef
   		if ($need_urgent && (!($request->[1] & TQM_URGENT)));
   	$request->[2]--
   		unless ($request->[2] == TQM_FIRST_ONLY);
   	delete $obj->[TQM_SUB_MAP]{$msgid}
   		if ($request->[2] <= 0);
   	return $request;
}

sub dequeue  {
    my $obj = shift;
    my $request;
    my $id = $obj->[TQM_SUB_ID_MAP]{threads->self()->tid() + 1};
    $@ = 'No subscriber for thread ' . threads->self()->tid(),
    return undef
    	unless $id;

	my $q = $obj->[TQD_Q];
    while (1) {

		lock(@$q);
		my $s = $obj->[TQM_SUBSCRIBERS]{$id};

    	cond_wait @$q
    		while (! scalar @$s);

#   print $id, " dequeue\n";

		$request = $obj->_get_request(shift @$s);
		next unless $request;
#
#	signal any waiters
#
    	cond_broadcast @$q;
    	last;
    }
    return _filter_dq($request);
}

sub dequeue_until {
    my ($obj, $timeout) = @_;

    return undef
    	unless $timeout && ($timeout > 0);

	$timeout += time();
	my $request;
    my $id = $obj->[TQM_SUB_ID_MAP]{threads->self()->tid() + 1};
    $@ = 'No subscriber for thread ' . threads->self()->tid(),
    return undef
    	unless $id;

	my $q = $obj->[TQD_Q];
	while (1)
	{
		lock(@$q);
		my $s = $obj->[TQM_SUBSCRIBERS]{$id};

   		cond_timedwait(@$q, $timeout)
	   		while (! scalar @$s) && ($timeout > time());
#
#	if none, then we must've timed out
#
		return undef
			unless scalar @$s;

#   print $id, " dequeue_until\n";

		$request = $obj->_get_request(shift @$s);
		next unless $request;
#
#	signal any waiters
#
    	cond_broadcast @$q;
    	last;
	}
    return _filter_dq($request);
}

sub dequeue_nb {
    my $obj = shift;
    my $request;
    my $id = $obj->[TQM_SUB_ID_MAP]{threads->self()->tid() + 1};
    $@ = 'No subscriber for thread ' . threads->self()->tid(),
    return undef
    	unless $id;
    my $q = $obj->[TQD_Q];
    while (1)
    {
		lock(@$q);
		my $s = $obj->[TQM_SUBSCRIBERS]{$id};
		return undef
			unless scalar @$s;
#   print $id, " dequeue_nb\n";
#
		$request = $obj->_get_request(shift @$s);
		return undef unless $request;
#
#	signal any waiters
#
    	cond_broadcast @$q;
		last;
	}
    return _filter_dq($request);
}

sub dequeue_urgent {
    my $obj = shift;
    my $request;
    my $id = $obj->[TQM_SUB_ID_MAP]{threads->self()->tid() + 1};
    $@ = 'No subscriber for thread ' . threads->self()->tid(),
    return undef
    	unless $id;
    my $q = $obj->[TQD_Q];
    while (1)
    {
		lock(@$q);
		my $s = $obj->[TQM_SUBSCRIBERS]{$id};
		return undef
			unless scalar @$s;

		$request = $obj->_get_request(shift @$s, 1);
		return undef unless $request;
#
#	signal any waiters
#
    	cond_broadcast @$q;
    	last;
	}
    return _filter_dq($request);
}

sub pending {
    my $obj = shift;
#
#	returned value depends on context: if its a
#	sub, return its queue; else return the
#	number of keys in the request map
#
    my $id = $obj->[TQM_SUB_ID_MAP]{threads->self()->tid() + 1};
	lock(@{$obj->[TQD_Q]});
	return scalar keys %{$obj->[TQM_SUB_MAP]}
		unless defined($id) && exists $obj->[TQM_SUBSCRIBERS]{$id};
#
#	Texas 2 step to avoid issues w/ threads::shared
#
	my $q = $obj->[TQM_SUBSCRIBERS]{$id};
	return scalar @$q;
}

#
#	common function for building response list
#
sub _create_resp {
	my @params : shared = ((undef) x (scalar @_ << 1));
#
#	marshall params, checking for Queueable objects
#
	my $i = 0;
	foreach (@_) {
		if (ref $_ &&
			(ref $_ ne 'ARRAY') &&
			(ref $_ ne 'HASH') &&
			(ref $_ ne 'SCALAR') &&
			$_->isa('Thread::Queue::Queueable')) {
#
#	invoke onEnqueue method
#
			$params[$i] = ref $_;
			$params[$i+1] = $_->onEnqueue();
		}
		else {
			@params[$i..$i+1] = (undef, $_);
		}
		$i += 2;
	}
	return \@params;
}

sub respond {
	my $obj = shift;
	my $msgid = shift;
    my $id = $obj->[TQM_SUB_ID_MAP]{threads->self()->tid() + 1};
    $@ = 'No subscriber for thread ' . threads->self()->tid(),
    return undef
    	unless $id;
#
#	silently ignore response to a simplex request
#
	return $obj unless defined($msgid);

	my $result = _create_resp(@_);
	my $pending;
	{
		lock(%{$obj->[TQM_PENDING_MAP]});
#
#	check if its been canceled
#
		_cancel_resp({ $id => $result }),
		return $obj
			unless exists $obj->[TQM_PENDING_MAP]{$msgid};
		$pending = $obj->[TQM_PENDING_MAP]{$msgid};
#
#	else post result, update refcount, and if done,
#	post completion; make sure we use same lock order
#	everywhere
#
		$pending->{$id} = $result;
		$pending->{_refcnt}--
			if $pending->{_refcnt} && ($pending->{_refcnt} > 0);

		if ($pending->{_refcnt} <= 0) {
			delete $pending->{_refcnt};
			lock(%{$obj->[TQD_MAP]});
			$obj->[TQD_MAP]{$msgid} = delete $obj->[TQM_PENDING_MAP]{$msgid};
		    cond_broadcast %{$obj->[TQD_MAP]};
#
#	order is important; we always lock MAP before MARK
#
			lock(%{$obj->[TQD_MARKS]});
			delete $obj->[TQD_MARKS]{$msgid};
		}
	}

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);

	return $obj;
}
#
#	common function for filtering response list
#
sub _filter_resp {
	my ($obj, $result) = @_;
#
#	collapse the response elements
#
	delete $result->{_refcnt};
	my %results = ();
	my $class;
	my $persub;
	my $subresp;
	foreach (keys %$result) {
		$results{$_} = $subresp = [];
		$persub = $result->{$_};
		$class = shift @$persub,
		push (@$subresp,
			$class ?
			${class}->onDequeue(shift @$persub) :
			shift @$persub)
			while (@$persub);
	}
    return \%results;
}
#
#	called to post completion when a sub unsubscribes
#
sub _post_complete {
	my $obj = shift;

	my $count = 0;
	{
#
#	note: lock order is important!
#
		lock(%{$obj->[TQM_PENDING_MAP]});
		lock(%{$obj->[TQD_MAP]});
		lock(%{$obj->[TQD_MARKS]});
		foreach (@_) {
			delete $obj->[TQD_MARKS]{$_};
#
#	check if its been canceled
#
			next
				unless exists $obj->[TQM_PENDING_MAP]{$_};
#
#	Texas 2 step to avoid threads::shared misbehavior
#
			my $pending = delete $obj->[TQM_PENDING_MAP]{$_};
			delete $pending->{_refcnt};
			$obj->[TQD_MAP]{$_} = $pending;
			$count++;
		}

	    cond_broadcast %{$obj->[TQD_MAP]}
	    	if $count;
	}

	if ($count) {
		lock($tqd_global_lock);
		cond_broadcast($tqd_global_lock);
	}
	return $obj;
}

sub _cancel_resp {
	my $resp = shift;
#
#	collapse the response elements,
#	and call onCancel to any that are Queueables
#
	my $class;
	delete $resp->{_refcnt};
	foreach (values %$resp) {
		$class = shift @$_,
		$class ?
			${class}->onCancel(shift @$_) :
			shift @$_
			while (@$_);
	}
    return 1;
}

sub cancel {
	my $obj = shift;
#
#	*always* lock in this order to avoid deadlock
#
	lock(@{$obj->[TQD_Q]});
	lock(%{$obj->[TQM_PENDING_MAP]});
	lock(%{$obj->[TQD_MAP]});
	lock(%{$obj->[TQD_MARKS]});
	foreach (@_) {
		delete $obj->[TQD_MARKS]{$_};
#
#	delete submap entry,
#	and purge any pending responses
#
		delete $obj->[TQM_SUB_MAP]{$_}
			if exists $obj->[TQM_SUB_MAP]{$_};
#
#	if already responded to, call onCancel for any Queueuables
#
		my $resp =
			(exists $obj->[TQM_PENDING_MAP]{$_}) ?
				delete $obj->[TQM_PENDING_MAP]{$_} :
			(exists $obj->[TQD_MAP]{$_}) ?
				delete $obj->[TQD_MAP]{$_} :
				undef;
		_cancel_resp($resp) if $resp;
	}
	return $obj;
}

sub cancel_all {
	my $obj = shift;
#
#	when we lock both, *always* lock in this order to avoid
#	deadlock
#
	lock(@{$obj->[TQD_Q]});
	lock(%{$obj->[TQM_PENDING_MAP]});
	lock(%{$obj->[TQD_MAP]});
	lock(%{$obj->[TQD_MARKS]});
#
#	first cancel all pending responses
#
	_cancel_resp(delete $obj->[TQM_PENDING_MAP]{$_})
		foreach (keys %{$obj->[TQM_PENDING_MAP]});

	_cancel_resp(delete $obj->[TQD_MAP]{$_})
		foreach (keys %{$obj->[TQD_MAP]});
#
#	then cancel all the pending requests by
#	setting their IDs to -1
#
	delete $obj->[TQD_MARKS]{$_},
	delete $obj->[TQM_SUB_MAP]{$_}
		foreach (keys %{$obj->[TQM_SUB_MAP]});
#
#	how will we cancel inprogress requests ??
#	need a map value, or alternate map...
#
	return $obj;
}

1;
