#/**
# Thread-safe request/response queue with identifiable elements.
# Provides methods for N threads to queue items to other threads, and
# then wait only for responses to specific queued items.
# <p>
# Note: this object is derived from an threads::shared arrayref
# to optimize performance.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$obj
# @see		<a href='./Queueable.html'>Thread::Queue::Queueable</a>
# @exports	$tqd_global_lock	global threads::shared variable for locking
# @exports	TQD_Q				object field index of threads::shared array used for the queue
# @exports	TQD_MAP				object field index of threads::shared hash mapping queue request IDs to requests/responses
# @exports	TQD_IDGEN			object field index of threads::shared scalar integer used to generate request IDs
# @exports	TQD_LISTENERS		object field index of threads::shared scalar integer count of current listeners
# @exports	TQD_REQUIRE_LISTENER object field index of threads::shared scalar flag indicating if listeners are required before permitting an enqueue operation
# @exports	TQD_MAX_PENDING		object field index of threads::shared scalar integer max number of pending requests before an enqueue will block
# @exports	TQD_URGENT_COUNT	object field index of threads::shared scalar integer count of current urgent requests
# @exports	TQD_MARKS			object field index of threads::shared hash mapping request IDs of marked requests
#*/
package Thread::Queue::Duplex;
#
#	Copyright (C) 2005,2006, Presicient Corp., USA
#
require 5.008;

use threads;
use threads::shared;
use Thread::Queue::Queueable;
use Thread::Queue::TQDContainer;
use Exporter;
use base qw(Exporter Thread::Queue::Queueable Thread::Queue::TQDContainer);

BEGIN {

use constant TQD_Q => 0;
use constant TQD_MAP => 1;
use constant TQD_IDGEN => 2;
use constant TQD_LISTENERS => 3;
use constant TQD_REQUIRE_LISTENER => 4;
use constant TQD_MAX_PENDING => 5;
use constant TQD_URGENT_COUNT => 6;
use constant TQD_MARKS => 7;

our @EXPORT    = ();		    # we export nothing by default
our @EXPORT_OK = qw($tqd_global_lock);

our %EXPORT_TAGS = (
	tqd_codes => [
		qw/TQD_Q TQD_MAP TQD_IDGEN TQD_LISTENERS TQD_REQUIRE_LISTENER
		TQD_MAX_PENDING TQD_URGENT_COUNT TQD_MARKS/
	]);

Exporter::export_tags(keys %EXPORT_TAGS);
}

use strict;
use warnings;
#
#	global semaphore used for class-level wait()
#	notification
#
our $tqd_global_lock : shared = 0;
our $tqd_debug : shared = 0;
our $VERSION = '0.92';

#/**
# Constructor. Creates a new empty queue, and associated mapping hash.
#
# @param ListenerRequired	boolean value indicating if registered listener
#							required before enqueue is permitted.
# @param MaxPending			positive integer maximum number of pending requests;
#							enqueue attempts will block until the pending count
# 							drops below this value. The limit may be applied or modified later
# 							via the <a href='#set_max_pending'>set_max_pending()</a> method.
#							A value of zero indicates no limit.
#
# @return		Thread::Queue::Duplex object
#*/
sub new {
    my $class = shift;

    $@ = 'Invalid argument list',
    return undef
    	if (scalar @_ && (scalar @_ & 1));

    my %args = @_;
    foreach (keys %args) {
	    $@ = 'Invalid argument list',
	    return undef
	    	unless ($_ eq 'ListenerRequired') ||
	    		($_ eq 'MaxPending');

	    $@ = 'Invalid argument list',
	    return undef
	    	if (($_ eq 'MaxPending') &&
	    		defined($args{$_}) &&
	    		(($args{$_}!~/^\d+/) || ($args{$_} < 0)));
    }
    my $idgen : shared = 1;
    my $listeners : shared = 0;
	my $max_pending : shared = $args{MaxPending} || 0;
	my $urgent_count : shared = 0;
	my %marks : shared = ();
    my @obj : shared = (
    	&share([]),
    	&share({}),
    	\$idgen,
    	\$listeners,
    	$args{ListenerRequired},
    	\$max_pending,
    	\$urgent_count,
    	\%marks
    );

    return bless \@obj, $class;
}

#/**
# Register as a queue listener. Permits "ListenerRequired"
# queues to accept requests when at least one listener
# has registered.
#
# @return		Thread::Queue::Duplex object
#*/
sub listen {
	my $obj = shift;
	lock(${$obj->[TQD_LISTENERS]});
	${$obj->[TQD_LISTENERS]}++;
	cond_broadcast(${$obj->[TQD_LISTENERS]});
	return $obj;
}

#/**
# Deregister as a queue listener. When all listeners
# deregister, a "ListenerRequired" queue will no longer
# accept new requests until a listener registers via
# <a href='#listen'>listen()</a>
#
# @return		Thread::Queue::Duplex object
#*/
sub ignore {
	my $obj = shift;
	lock(${$obj->[TQD_LISTENERS]});
	${$obj->[TQD_LISTENERS]}--
		if ${$obj->[TQD_LISTENERS]};
	return $obj;
}

#/**
# Wait until a listener has registered.
#
# @param $timeout	(optional) number of seconds to wait for a listener.
#
# @return		Thread::Queue::Duplex if a listener is registered; undef otherwise.
#*/
sub wait_for_listener {
	my ($obj, $timeout) = shift;
	my $listeners = $obj->[TQD_LISTENERS];
	lock($$listeners);

	return undef
		if ($timeout && ($timeout < 0));

	if ($timeout) {
		$timeout += time();
		cond_timedwait($$listeners, $timeout)
			while (!$$listeners) && ($timeout > time());

		return $$listeners ? $obj : undef;
	}
	cond_wait($$listeners)
		while (!$$listeners);

	return $$listeners ? $obj : undef;
}
#
#	common function for build enqueue list
#
sub _filter_nq {
	my $id = shift;
	my @params : shared = ($id, (undef) x (scalar @_ << 1));
#
#	marshall params, checking for Queueable objects
#
	my $i = 1;
	foreach (@_) {
		@params[$i..$i+1] =
			(ref $_ &&
			(ref $_ ne 'ARRAY') &&
			(ref $_ ne 'HASH') &&
			(ref $_ ne 'SCALAR') &&
			$_->isa('Thread::Queue::Queueable')) ?
			$_->onEnqueue() : (undef, $_);
#
#	invoke onEnqueue method
#
#			$params[$i] = ref $_;
#			$params[$i+1] = $_->onEnqueue();
#		}
#		else {
#			@params[$i..$i+1] = (undef, $_);
#		}
		$i += 2;
	}
	return \@params;
}

sub _lock_load {
	my ($obj, $params, $urgent) = @_;
	lock(@{$obj->[TQD_Q]});
#
#	check current length if we have a limit
#
	while (${$obj->[TQD_MAX_PENDING]} &&
		(${$obj->[TQD_MAX_PENDING]} <= scalar @{$obj->[TQD_Q]})) {
#		print "pending before: ", scalar @{$obj->[TQD_Q]}, "\n";
		cond_wait(@{$obj->[TQD_Q]});
#		print "pending after: ", scalar @{$obj->[TQD_Q]}, "\n";
	}

	if ($urgent) {
	    unshift @{$obj->[TQD_Q]}, $params;
	    ${$obj->[TQD_URGENT_COUNT]}++;
	}
	else {
	    push @{$obj->[TQD_Q]}, $params;
	}
    cond_signal @{$obj->[TQD_Q]};
    1;
}

sub _get_id {
	my $obj = shift;

	lock(${$obj->[TQD_IDGEN]});
	my $id = ${$obj->[TQD_IDGEN]}++;
#
#	rollover, just in case...not perfect,
#	but good enough
#
	${$obj->[TQD_IDGEN]} = 1
		if (${$obj->[TQD_IDGEN]} > 2147483647);
	return $id;
}

#/**
# Enqueue a request to the tail of the queue.
#
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Request ID if successful; undef if ListenerRequired and no listeners
#				are registered
#*/
sub enqueue {
    my $obj = shift;

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));
	my $id = $obj->_get_id;

	my $params = _filter_nq($id, @_);
	_lock_load($obj, $params);
	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $id;
}

#/**
# Enqueue a request to the head of the queue.
#
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Request ID if successful; undef if ListenerRequired and no listeners
#				are registered
#*/
sub enqueue_urgent {
    my $obj = shift;

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));
	my $id = $obj->_get_id;
	my $params = _filter_nq($id, @_);
	_lock_load($obj, $params, 1);

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $id;
}
#
#	blocking versions of enqueue()
#
#/**
# Enqueue a request to the tail of the queue, and wait for the response.
#
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Response structure if successful; undef if ListenerRequired and no listeners
#				are registered
#*/
sub enqueue_and_wait {
    my $obj = shift;

	my $id = $obj->enqueue(@_);
	return undef
		unless defined($id);
	return $obj->wait($id);
}

#/**
# Enqueue a request to the tail of the queue, and wait up to $timeout seconds
# for the response.
#
# @param $timeout number of seconds to wait for a response
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Response structure if successful; undef if ListenerRequired and no listeners
#				are registered, or if no response is received within the specified $timeout
#*/
sub enqueue_and_wait_until {
    my $obj = shift;
	my $timeout = shift;

	my $id = $obj->enqueue(@_);
	return undef
		unless defined($id);
	return $obj->wait_until($id, $timeout);
}

#/**
# Enqueue a request to the head of the queue, and wait up to $timeout seconds
# for the response.
#
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Response structure if successful; undef if ListenerRequired and no listeners
#				are registered
#*/
sub enqueue_urgent_and_wait {
    my $obj = shift;

	my $id = $obj->enqueue_urgent(@_);
	return undef
		unless defined($id);
	return $obj->wait($id);
}

#/**
# Enqueue a request to the head of the queue, and wait up to $timeout seconds
# for the response.
#
# @param $timeout number of seconds to wait for a response
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Response structure if successful; undef if ListenerRequired and no listeners
#				are registered, or if no response is received within the specified $timeout
#*/
sub enqueue_urgent_and_wait_until {
    my $obj = shift;
	my $timeout = shift;

	my $id = $obj->enqueue_urgent(@_);
	return undef
		unless defined($id);
	return $obj->wait_until($id, $timeout);
}
#
#	Simplex versions
#
#/**
# Enqueue a simplex request to the tail of the queue. Simplex requests
# do not generate responses.
#
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Thread::Queue::Duplex object if successful; undef if ListenerRequired and
#				no listeners are registered
#*/
sub enqueue_simplex {
    my $obj = shift;

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));

	my $params = _filter_nq(undef, @_);
	_lock_load($obj, $params);

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $obj;
}

#/**
# Enqueue a simplex request to the head of the queue. Simplex requests
# do not generate responses.
#
# @param @args	the request. Request values must be either scalars,
#				references to threads::shared variables, or Thread::Queue::Queueable
#				objects
#
# @return		Thread::Queue::Duplex object if successful; undef if ListenerRequired and
#				no listeners are registered
#*/
sub enqueue_simplex_urgent {
    my $obj = shift;

	return undef
		if ($obj->[TQD_REQUIRE_LISTENER] &&
			(! ${$obj->[TQD_LISTENERS]}));

	my $params = _filter_nq(undef, @_);
	_lock_load($obj, $params, 1);

	lock($tqd_global_lock);
	cond_broadcast($tqd_global_lock);
    return $obj;
}
#
#	recover original param list, including reblessing Queueables
#
sub _filter_dq {
	my $result = shift;
#
#	keep ID; collapse the rest
#
	my @results = (shift @$result);
	my $class;
	$class = shift @$result,
	push (@results,
		$class ?
		${class}->onDequeue(shift @$result) :
		shift @$result)
		while (@$result);
    return \@results;
}

#/**
# Dequeue the next request. Waits until a request is available before
# returning.
#
# @return		arrayref of request values. The request ID is the first element
#				in the returned array.
#*/
sub dequeue  {
    my $obj = shift;
    my $request;
    my $q = $obj->[TQD_Q];
    while (1) {
#
#	lock order is important here
#
		lock(@$q);
    	cond_wait @$q
    		until scalar @$q;
    	$request = shift @$q;
#   print threads->self()->tid(), " dequeue\n";
    	${$obj->[TQD_URGENT_COUNT]}--
    		if ${$obj->[TQD_URGENT_COUNT]};
#
#	cancelled request ?
#
   		next
   			if ($request->[0] && ($request->[0] == -1));
#
#	check for cancel
#
		{
			lock(%{$obj->[TQD_MAP]});
			delete $obj->[TQD_MAP]{$request->[0]},
			next
				if ($request->[0] &&
					exists $obj->[TQD_MAP]{$request->[0]});
		}
#
#	signal any waiters
#
    	cond_broadcast @{$obj->[TQD_Q]};
    	last;
    }
    return _filter_dq($request);
}

#/**
# Dequeue the next request. Waits until a request is available, or up to
# $timeout seconds, before returning.
#
# @param $timeout number of seconds to wait for a request
#
# @return		undef if no request available within $timeout seconds. Otherwise,
#				arrayref of request values. The request ID is the first element
#				in the returned array.
#*/
sub dequeue_until {
    my ($obj, $timeout) = @_;

    return undef
    	unless $timeout && ($timeout > 0);

	$timeout += time();
	my $request;

	while (1)
	{
		lock(@{$obj->[TQD_Q]});

		print STDERR "dq_until...\n"
			if $tqd_debug;

		cond_timedwait(@{$obj->[TQD_Q]}, time() + 1)
			while (($timeout > time()) && (! scalar @{$obj->[TQD_Q]}));

		print STDERR "dq_until done...\n"
			if $tqd_debug;

#
#	if none, then we must've timed out
#
		return undef
			unless scalar @{$obj->[TQD_Q]};

		$request = shift @{$obj->[TQD_Q]};
#   print threads->self()->tid(), " dequeue_until\n";
    	${$obj->[TQD_URGENT_COUNT]}--
    		if ${$obj->[TQD_URGENT_COUNT]};
#
#	cancelled request ?
#
   		next
   			if ($request->[0] && ($request->[0] == -1));
#
#	check for cancel
#
		{
			lock(%{$obj->[TQD_MAP]});
			delete $obj->[TQD_MAP]{$request->[0]},
			next
				if ($request->[0] &&
					exists $obj->[TQD_MAP]{$request->[0]});
		}
#
#	signal any waiters
#
    	cond_broadcast @{$obj->[TQD_Q]};
    	last;
	}
    return _filter_dq($request);
}

#/**
# Dequeue the next request. Returns immediately if no request is available.
#
# @return		undef if no request available; otherwise,
#				arrayref of request values. The request ID is the first element
#				in the returned array.
#*/
sub dequeue_nb {
    my $obj = shift;
    my $request;
    while (1)
    {
		lock(@{$obj->[TQD_Q]});
		return undef
			unless scalar @{$obj->[TQD_Q]};
		$request = shift @{$obj->[TQD_Q]};
#   print threads->self()->tid(), " dequeue_nb\n";
    	${$obj->[TQD_URGENT_COUNT]}--
    		if ${$obj->[TQD_URGENT_COUNT]};
#
#	cancelled request ?
#
   		next
   			if ($request->[0] && ($request->[0] == -1));
#
#	check for cancel (ie, the request is already in the map)
#
		{
			lock(%{$obj->[TQD_MAP]});
			delete $obj->[TQD_MAP]{$request->[0]},
			next
				if ($request->[0] &&
					exists $obj->[TQD_MAP]{$request->[0]});
		}
#
#	signal any waiters
#
    	cond_broadcast @{$obj->[TQD_Q]};
		last;
	}
    return _filter_dq($request);
}

#/**
# Dequeue the next urgent request. Waits until an urgent request is available before
# returning.
#
# @return		arrayref of request values. The request ID is the first element
#				in the returned array.
#*/
sub dequeue_urgent {
    my $obj = shift;
    my $request;
    while (1)
    {
		lock(@{$obj->[TQD_Q]});
		return undef
			unless (scalar @{$obj->[TQD_Q]}) &&
				${$obj->[TQD_URGENT_COUNT]};
		$request = shift @{$obj->[TQD_Q]};
    	${$obj->[TQD_URGENT_COUNT]}--
    		if ${$obj->[TQD_URGENT_COUNT]};
#
#	cancelled request ?
#
   		next
   			if ($request->[0] && ($request->[0] == -1));
#
#	check for cancel
#
		{
			lock(%{$obj->[TQD_MAP]});
			delete $obj->[TQD_MAP]{$request->[0]},
			next
				if ($request->[0] &&
					exists $obj->[TQD_MAP]{$request->[0]});
		}
#
#	signal any waiters
#
    	cond_broadcast @{$obj->[TQD_Q]};
    	last;
	}
    return _filter_dq($request);
}

#/**
# Report the number of pending requests.
#
# @return		number of requests remaining in the queue.
#*/
sub pending {
    my $obj = shift;
	lock(@{$obj->[TQD_Q]});
	lock(%{$obj->[TQD_MAP]});
	my $p = scalar @{$obj->[TQD_Q]};
	my $i;
	foreach (@{$obj->[TQD_Q]}) {
		next unless $_ && ref $_ && (ref $_ eq 'ARRAY') && $_->[0];
#
#	NOTE: this intermediate assignment is required for no apparent
#	reason in order to keep from getting "Free to wrong pool" aborts
#
		$i = $_->[0];
		$p--
			if ($i == -1) || exists($obj->[TQD_MAP]{$i});
	}
	return $p;
}

#/**
# Set maximum number of pending requests permitted. Signals any
# currently threads which may be blocked waiting for the number
# of pending requests to drop below the maximum permitted.
#
# @param $limit		positive integer maximum number of pending requests permitted.
#					A value of zero indicates no limit.
#
# @return		Thread::Queue::Duplex object
#*/
sub set_max_pending {
    my ($obj, $limit) = @_;
    $@ = 'Invalid limit.',
    return undef
    	unless (defined($limit) && ($limit=~/^\d+/) && ($limit >= 0));

	lock(@{$obj->[TQD_Q]});
    ${$obj->[TQD_MAX_PENDING]} = $limit;
#
#	wake up anyone whos been waiting for queue to change
#
	cond_broadcast(@{$obj->[TQD_Q]});
    return $obj;
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

#/**
# Post a response to a request. If the request has been cancelled,
# the response is discarded; otherwise, all threads blocked on the
# queue are signalled that a new response is available.
#
# @param $id		the ID of the request being responded to.
# @param @response	the response. Response values must be either scalars,
#					references to threads::shared variables, or Thread::Queue::Queueable
#					objects
#
# @return		Thread::Queue::Duplex object
#*/
sub respond {
	my $obj = shift;
	my $id = shift;
#
#	silently ignore response to a simplex request
#
	return $obj unless defined($id);

	my $result = _create_resp(@_);
	{
		lock(%{$obj->[TQD_MARKS]});
		delete $obj->[TQD_MARKS]{$id};

		print STDERR "respond: locking for $id at ", time(), "\n"
			if $tqd_debug;

		lock(%{$obj->[TQD_MAP]});

		print STDERR "respond: locked for $id at ", time(), "\n"
			if $tqd_debug;
#
#	check if its been canceled
#
		_cancel_resp($result),
		return $obj
			if exists $obj->[TQD_MAP]{$id};

		$obj->[TQD_MAP]{$id} = $result;
#	    cond_signal %{$obj->[TQD_MAP]};
 	    cond_broadcast(%{$obj->[TQD_MAP]});
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
	my @results = ();
	my $class;
	$class = shift @$result,
	push (@results,
		$class ?
		${class}->onDequeue(shift @$result) :
		shift @$result)
		while (@$result);
    return \@results;
}

#/**
# Wait for a response to a request. Also available as <code>dequeue_response()</code>
# alias.
#
# @param $id		the request ID of the response for which to wait.
#
# @return 			the response as an arrayref.
#*/
sub wait {
	my $obj = shift;
	my $id = shift;

 	my $reqmap = $obj->[TQD_MAP];
	my $result;
	{
 		lock(%$reqmap);
 		unless ($$reqmap{$id}) {
 		    cond_wait %$reqmap
 		    	until $$reqmap{$id};
 		}
     	$result = delete $$reqmap{$id};
     	cond_signal %$reqmap
     		if keys %$reqmap;
    }
    return $obj->_filter_resp($result);
}
*dequeue_response = \&wait;

#/**
# Test if a response is available for a specific request.
#
# @param $id		the request ID of the response for which to test.
#
# @return 			Thread::Queue::Duplex object if response is available; undef otherwise.
#*/
sub ready {
	my $obj = shift;
	my $id = shift;
#
#	no lock really needed here...
#
    return defined($obj->[TQD_MAP]{$id}) ? $obj : undef;
}

#/**
# Test if a response is available for a either any request,
# or for any of a set of requests.
#
# @param @ids		(optional) list of request IDs of responses for which to test.
#
# @return 			first request ID of available responses, or undef if none available
# @returnlist 		list of request IDs of available responses, or undef if none available
#*/
sub available {
	my $obj = shift;

	my @ids = ();
 	my $reqmap = $obj->[TQD_MAP];
 	lock(%$reqmap);
	if (scalar @_) {
#		print STDERR "available with a list\n";
 		map { push @ids, $_ if $$reqmap{$_}; } @_;
	}
	else {
#		print STDERR "available without list\n";
 		@ids = keys %$reqmap;
	}
    return scalar @ids ? wantarray ? @ids : $ids[0] : undef;
}

#/**
# Wait up to $timeout seconds for a response to a request.
#
# @param $id		the request ID of the response for which to wait.
# @param $timeout	number of seconds to wait
#
# @return 			the response as an arrayref, or undef if none available within the timeout
#*/
sub wait_until {
	my ($obj, $id, $timeout) = @_;

    return undef
    	unless $timeout && ($timeout > 0);
	$timeout += time();
	my $result;
 	my $reqmap = $obj->[TQD_MAP];
 	my $tid = threads->self()->tid();

 	while ($timeout > time()) {
 		lock(%$reqmap);

		print STDERR "wait_until in $tid for $id at ", time(), "\n"
			if $tqd_debug;

   		cond_timedwait(%$reqmap, $timeout)
   			unless $$reqmap{$id};

		print STDERR "wait_until in $tid for $id signaled at ", time(), "\n"
			if $tqd_debug;

		next unless $$reqmap{$id};

		print STDERR "wait_until in $tid for $id done ", time(), "\n"
			if $tqd_debug;

		print STDERR "avail keys in $tid ", join(', ', keys %$reqmap), "\n"
		 	if $tqd_debug;

 	   	$result = delete $$reqmap{$id};

 	    cond_broadcast %$reqmap;
 		last;
	}
    return $result ? $obj->_filter_resp($result) : undef;
}
#
#	some grouped waits
#	wait indefinitely for *any* of the
#	supplied ids
#
#/**
# Wait for a response to any specified request. May be called as either
# an instance or class method.
# <p>
# As an instance method, a list of request IDs is provided, and the method waits for
# a response event on any of the specified requests.
# <p>
# As a class method, the caller provides a list of either Thread::Queue::TQDContainer
# objects (<i>TQD is itself a TQDContainer</i>),
# or arrayrefs with a Thread::Queue::TQDContainer object, and zero or more request
# IDs. For Thread::Queue::TQDContainer object arguments, and arrayref arguments
# with no identifiers, waits for any enqueue event on the contained queue.
# For arrayref arguments with IDS, waits for a response event for any
# of the specified IDs.
#
# @param @IDs_or_container_refs	as instance method, a list of request IDs to wait for;
#						as class method, a list of either of Thread::Queue::TQDContainer objects,
#						or arrayrefs containing a Thread::Queue::TQDContainer object, followed by
#						zero or more request IDs for the queue object.
#
# @return 		as an instance method, returns a hashref of request IDs mapped to their response;
#				as a class method, returns a list of TQD containers which have events pending.
#*/
sub wait_any {
	my $obj = shift;
	return _tqd_wait(undef, undef, @_)
		unless ref $obj;
	my $reqmap = $obj->[TQD_MAP];
	my %responses = ();
	{
		lock(%$reqmap);
#
#	cond_wait isn't behaving as expected, so we need to
#	test first, then wait if needed
#
   		map {
   			$responses{$_} = delete $$reqmap{$_}
   				if $$reqmap{$_};
   		} @_;

		until (keys %responses) {
			cond_wait %$reqmap;
		   	map {
		   		$responses{$_} = delete $$reqmap{$_}
		   			if $$reqmap{$_};
		   	} @_;
#
#	go ahead and signal...if no one's waiting, no harm
#
		    cond_signal %$reqmap;
		}
	}
	$responses{$_} = $obj->_filter_resp($responses{$_})
		foreach (keys %responses);
    return \%responses;
}
#
#	wait up to timeout for any
#
#/**
# Wait up to $timeout seconds for a response to any specified request. May be called as either
# an instance or class method.
# <p>
# As an instance method, a list of request IDs is provided, and the method waits for
# a response event on any of the specified requests.
# <p>
# As a class method, the caller provides a list of either Thread::Queue::TQDContainer objects,
# or arrayrefs with a Thread::Queue::TQDContainer object, and zero or more request
# IDs. For Thread::Queue::TQDContainer object arguments, and arrayref arguments
# with no identifiers, waits for any enqueue event on the queue.
# For arrayref arguments with IDS, waits for a response event for any
# of the specified IDs.
#
# @param $timeout		number of seconds to wait for a response event
# @param @IDs_or_container_refs	as instance method, a list of request IDs to wait for;
#						as class method, a list of either of Thread::Queue::TQDContainer objects,
#						or arrayrefs containing a Thread::Queue::TQDContainer object, followed by
#						zero or more request IDs for the queue object.
#
# @return 		undef if no response events occured within $timeout seconds; otherwise,
#				as an instance method, returns a hashref of request IDs mapped to their response;
#				as a class method, returns a list of queues which have events pending.
#*/
sub wait_any_until {
	my $obj = shift;
	return _tqd_wait(shift, undef, @_)
		unless ref $obj;

	my $timeout = shift;

	return undef unless $timeout && ($timeout > 0);
	$timeout += time();
	my $reqmap = $obj->[TQD_MAP];
	my %responses = ();
	{
		lock(%$reqmap);
#
#	cond_wait isn't behaving as expected, so we need to
#	test first, then wait if needed
#
	   	map {
	   		$responses{$_} = delete $$reqmap{$_}
	   			if $$reqmap{$_};
	   	} @_;

		while ((! keys %responses) && ($timeout > time())) {
			cond_timedwait(%$reqmap, $timeout);

	   		map {
		   		$responses{$_} = delete $$reqmap{$_}
	   				if $$reqmap{$_};
	   		} @_;
#
#	go ahead and signal...if no one's waiting, no harm
#
		    cond_signal %$reqmap;
		}
	}
	$responses{$_} = $obj->_filter_resp($responses{$_})
		foreach (keys %responses);
    return keys %responses ? \%responses : undef;
}
#/**
# Wait for a response to all specified requests. May be called as either
# an instance or class method.
# <p>
# As an instance method, a list of request IDs is provided, and the method waits for
# a response event on all of the specified requests.
# <p>
# As a class method, the caller provides a list of either Thread::Queue::TQDContainer objects,
# or arrayrefs with a Thread::Queue::TQDContainer object, and zero or more request
# IDs. For Thread::Queue::TQDContainer object arguments, and arrayref arguments
# with no identifiers, waits for responses to all current requests on the queue.
# For arrayref arguments with IDS, waits for a response to all
# of the specified IDs.
#
# @param @IDs_or_container_refs	as instance method, a list of request IDs to wait for;
#						as class method, a list of either of Thread::Queue::TQDContainer objects,
#						or arrayrefs containing a Thread::Queue::TQDContainer object, followed by
#						zero or more request IDs for the queue object.
#
# @return 		as an instance method, returns a hashref of request IDs mapped to their response;
#				as a class method, returns a list of queues which have events pending.
#*/
sub wait_all {
	my $obj = shift;
	return _tqd_wait(undef, 1, @_)
		unless ref $obj;
	my $reqmap = $obj->[TQD_MAP];
	my %responses = ();
	{
		lock(%$reqmap);
	   	map {
	   		$responses{$_} = delete $$reqmap{$_}
	   			if $$reqmap{$_};
	   	} @_;
		until (scalar keys %responses == scalar @_) {
			cond_wait %$reqmap;

		   	map {
		   		$responses{$_} = delete $$reqmap{$_}
		   			if $$reqmap{$_};
		   	} @_;
#
#	go ahead and signal...if no one's waiting, no harm
#
		    cond_signal %$reqmap;
		}
	}
	$responses{$_} = $obj->_filter_resp($responses{$_})
		foreach (keys %responses);
    return \%responses;
}

#/**
# Wait up to $timeout seconds for a response to all specified requests. May be called as either
# an instance or class method.
# <p>
# As an instance method, a list of request IDs is provided, and the method waits for
# a response event on all of the specified requests.
# <p>
# As a class method, the caller provides a list of either Thread::Queue::TQDContainer objects,
# or arrayrefs with a Thread::Queue::TQDContainer object, and zero or more request
# IDs. For Thread::Queue::TQDContainer object arguments, and arrayref arguments
# with no identifiers, waits for responses to all current requests on the queue.
# For arrayref arguments with IDS, waits for a response to all
# of the specified IDs.
#
# @param $timeout		number of seconds to wait for all response
# @param @IDs_or_container_refs	as instance method, a list of request IDs to wait for;
#						as class method, a list of either of Thread::Queue::TQDContainer objects,
#						or arrayrefs containing a Thread::Queue::TQDContainer object, followed by
#						zero or more request IDs for the queue object.
#
# @return 		undef unless all response events occured within $timeout seconds; otherwise,
#				as an instance method, returns a hashref of request IDs mapped to their response;
#				as a class method, returns a list of queues which have events pending.
#*/
sub wait_all_until {
	my $obj = shift;

	return _tqd_wait(shift, 1, @_)
		unless ref $obj;

	my $timeout = shift;

	return undef unless $timeout && ($timeout > 0);
	$timeout += time();
	my $reqmap = $obj->[TQD_MAP];
	my %responses = ();
	{
		lock(%$reqmap);
   		map {
   			$responses{$_} = delete $$reqmap{$_}
   				if $$reqmap{$_};
   		} @_;
		while ((scalar keys %responses != scalar @_) &&
			($timeout > time())) {
			cond_timedwait(%$reqmap, $timeout);

   			map {
		   		$responses{$_} = $$reqmap{$_}
   					if $$reqmap{$_};
   			} @_;
#
#	go ahead and signal...if no one's waiting, no harm
#
		    cond_signal %$reqmap;
		}
#
#	if we got all our responses, then remove from map
#
		map { delete $$reqmap{$_} } @_
			if (scalar keys %responses == scalar @_);
	}
	$responses{$_} = $obj->_filter_resp($responses{$_})
		foreach (keys %responses);
#print 'list has ', scalar @_, ' we got ', scalar keys %responses, "\n";
    return (scalar keys %responses == scalar @_) ? \%responses : undef;
}

#/**
# Mark a request with a value. Provides a means to
# associate properties to a request after it has been
# queued, but before the response has been posted. The
# responder may test for marks via the <a href='#marked'>marked()</a>
# method, or retrieve the mark value via <a href='#get_mark'>get_mark()</a>.
#
# @param $id	ID of request to be marked
# @param $value	(optional) value to be added as a mark; if not specified,
#				a default value of 1 is used.
#
# @return		Thread::Queue::Duplex object
#*/
sub mark {
	my ($obj, $id, $value) = @_;

	$value = 1 unless defined($value);
	lock(%{$obj->[TQD_MAP]});
	lock(%{$obj->[TQD_MARKS]});
#
#	already responded or cancelled
#
	return undef
		if (exists $obj->[TQD_MAP]{$id});

	$obj->[TQD_MARKS]{$id} = $value;
	return $obj;
}

#/**
# Remove any marks from a request.
#
# @param $id	ID of request to be unmarked.
#
# @return		Thread::Queue::Duplex object
#*/
sub unmark {
	my ($obj, $id) = @_;

	lock(%{$obj->[TQD_MARKS]});
	delete $obj->[TQD_MARKS]{$id};
	return $obj;
}

#/**
# Returns any current mark on a specified request.
#
# @param $id	ID of request whose mark is to be returned.
#
# @return		the mark value; undef if not marked
#*/
sub get_mark {
	my ($obj, $id) = @_;
	lock(%{$obj->[TQD_MARKS]});
	return $obj->[TQD_MARKS]{$id};
}

#/**
# Test if a request is marked, or if the mark is a specified value.
#
# @param $id	ID of request to test for a mark
# @param $value	(optional) value to test for
#
# @return		1 if the request is marked and either no $value was specified,
#				or, if a $value was specified, the mark value equals $value; undef
#				otherwise.
#*/
sub marked {
	my ($obj, $id, $value) = @_;
	lock(%{$obj->[TQD_MARKS]});
	return (defined($obj->[TQD_MARKS]{$id}) &&
		((defined($value) && ($obj->[TQD_MARKS]{$id} eq $value)) ||
		(!defined($value))));
}

sub _cancel_resp {
	my $resp = shift;
#
#	collapse the response elements,
#	and call onCancel to any that are Queueables
#
	my $class;
	$class = shift @$resp,
	$class ?
		${class}->onCancel(shift @$resp) :
		shift @$resp
		while (@$resp);
    return 1;
}

#/**
# Cancel one or more pending requests.
# <p>
# If a response to a cancelled request has already been
# posted to the queue response map (i.e., the request has already
# been serviced), the response is removed from the map,
# the <a href='./Queueable.html#onCancel>onCancel()</a> method is
# invoked on each <a href='./Queueable.html>Thread::Queue::Queueable</a>
# object in the response, and the response is discarded.
# <p>
# If a response to a cancelled request has <b>not</b> yet been posted to
# the queue response map, an empty entry is added to the queue response map.
# (<b>Note:</b> threads::shared doesn't permit splicing shared arrays yet,
# so we can't remove the request from the queue).
# <p>
# When a server thread attempts to <code>dequeue[_nb|_until]()</code> a cancelled
# request, the request is discarded and the dequeue operation is retried.
# If the cancelled request is already dequeued, the server thread will
# detect the cancellation when it attempts to <a href='#respond'>respond</a> to the request,
# and will invoke the <a href='./Queueable.html#onCancel>onCancel()</a>
# method on any <a href='./Queueable.html>Thread::Queue::Queueable</a>
# objects in the response, and then discards the response.
# <p>
# <b>Note</b> that, as simplex requests do not have an identifier, there
# is no way to explicitly cancel a specific simplex request.
#
# @param @ids	list of request IDs to be cancelled.
#
# @return		Thread::Queue::Duplex object
#*/
sub cancel {
	my $obj = shift;
#
#	when we lock both, *always* lock in this order to avoid
#	deadlock
#
	lock(@{$obj->[TQD_Q]});
	lock(%{$obj->[TQD_MAP]});
	lock(%{$obj->[TQD_MARKS]});
	foreach (@_) {
		delete $obj->[TQD_MARKS]{$_};

		$obj->[TQD_MAP]{$_} = undef,
		next
			unless (exists $obj->[TQD_MAP]{$_});
#
#	already responded to, call onCancel for any Queueuables
#
		_cancel_resp(delete $obj->[TQD_MAP]{$_});
	}
	return $obj;
}

#/**
# Cancel <b>all</b> current requests and responses, using the
# <a href='#cancel'>cancel()</a> algorithm above, plus cancels
# all simplex requests still in the queue.
# <p>
# <b>Note:</b> In-progress requests (i.e.,
# request which have been removed from the queue, but do not yet
# have an entry in the response map)  will <b>not</b> be cancelled.
#
# @return		Thread::Queue::Duplex object
#*/
sub cancel_all {
	my $obj = shift;
#
#	when we lock both, *always* lock in this order to avoid
#	deadlock
#
	lock(@{$obj->[TQD_Q]});
	lock(%{$obj->[TQD_MAP]});
	lock(%{$obj->[TQD_MARKS]});
#
#	first cancel all pending responses
#
	_cancel_resp(delete $obj->[TQD_MAP]{$_})
		foreach (keys %{$obj->[TQD_MAP]});
#
#	then cancel all the pending requests by
#	setting their IDs to -1
#
#	UPDATED per bug reported on CPAN
#
#	delete $obj->[TQD_MARKS]{$_->[0]},
#	$_->[0] = -1
#		foreach (@{$obj->[TQD_Q]});
    foreach (@{$obj->[TQD_Q]}) {
	    delete $obj->[TQD_MARKS]{$_->[0]}
            if defined($_->[0]);
	    $_->[0] = -1;
    }
#
#	how will we cancel inprogress requests ??
#	need a map value, or alternate map...
#
	return $obj;
}
##########################################################
#
#	BEGIN CLASS LEVEL METHODS
#
##########################################################

sub _tqd_wait {
	my $timeout = shift;
	my $wait_all = shift;
#
#	validate params
#
	map {
		return undef
			unless ($_ &&
				ref $_ &&
				(
					((ref $_ eq 'ARRAY') &&
						($#$_ >= 0) &&
						ref $_->[0] &&
						$_->[0]->isa('Thread::Queue::TQDContainer')
					) ||
					$_->isa('Thread::Queue::TQDContainer')
				));
	} @_;

	my @avail = ();

	my @qs = ();
	my @containers = ();
	push(@containers, ((ref $_ eq 'ARRAY') ? $_->[0] : $_)),
	push(@qs, $containers[-1]->get_queue())
		foreach (@_);

#print join(', ', @qs), "\n";

	my ($q, $container, $ids);
	my $count = scalar @qs;
	my @ids;
	$timeout += time() if $timeout;
	while ($count) {
		lock($tqd_global_lock);
		foreach (0..$#_) {
			last unless $count;
			next unless $qs[$_];
			$q = $qs[$_];
			$container = $containers[$_];
			$ids = $_[$_];
#
#	if we've got ids, check for responses
#
			push(@avail, $container),
			$qs[$_] = undef,
			$count--
	    		if (((ref $ids eq 'ARRAY') && (scalar @$ids > 1)) ?
	    			$q->available(@{$ids}[1..$#$ids]) :
	    			$q->pending());

		}	# end foreach queue
		last
			unless (($wait_all && $count) || (! scalar @avail));

 		unless ($timeout) {

			print STDERR "TQD: locking...\n"
			 	if $tqd_debug;

	 		cond_wait($tqd_global_lock);
			print STDERR "TQD: locked\n"
			 	if $tqd_debug;

	 		next;
 		}
#		print STDERR "timed out and avail has ", scalar @avail, "\n" and
		cond_timedwait($tqd_global_lock, $timeout);
		return ()
			unless ($timeout > time());
	}

#print STDERR "avail has ", scalar @avail, "\n";
	return @avail;
}
##########################################################
#
#	END CLASS LEVEL METHODS
#
##########################################################
###############################################
#
#	All TQQ default methods can be used as is
#
###############################################
###############################################
#
#	TQDContainer overrides
#
###############################################
sub set_queue { return $_[0]; }

sub get_queue { return $_[0]; }

1;
