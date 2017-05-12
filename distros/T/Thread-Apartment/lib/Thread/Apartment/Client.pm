#/**
# Client proxy for apartment threaded objects.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
#*/
package Thread::Apartment::Client;

use Carp;
use threads;
use threads::shared;
use Thread::Queue::Queueable;
use Thread::Queue::TQDContainer;
use Thread::Apartment;
use Thread::Apartment::Common;

use Thread::Apartment::Common qw(:ta_method_flags);

use base qw(Thread::Queue::Queueable Thread::Queue::TQDContainer Thread::Apartment::Common);

our $AUTOLOAD;

use strict;
use warnings;

our $VERSION = '0.51';

use constant TAC_CLASS_LEN => 27;
use constant TAC_REENT_LEN => 13;
use constant TAC_ASYNC_LEN => 9;

our $async_method;	# set by T::A::start()

sub CLONE { $async_method = undef; }

#/**
# Constructor. Creates a threads::shared hash to contain the proxy
# information, so it can be readily passed between threads.
#
# @param $proxied_class		the class of the object to be proxied
# @param $tqd				TQD communications channel to proxied object
# @param $id				unique object ID for proxied object
# @param $isa				arrayref of object's class hierarchy
# @param $methods			hashref mapping exported method names to behavior flags
# @param $timeout			TQD timeout seconds
# @param $tid				thread ID of the apartment thread for the proxied object
#
# @return		Thread::Apartment::Client object
#*/
sub new {
	my ($class, $proxied_class, $tqd, $id, $isa, $methods, $timeout, $tid)= @_;
#
#	create isa, can as shared so we can curse/redeem them easily
#
	my @isa : shared = ( @$isa, 'ta_invoke_closure' );
	my %can : shared = ( %$methods );

	my %self : shared = (
		_class	=> $proxied_class,	# class we're proxying
		_id 	=> $id,				# object unique ID (for object hierarchies)
		_tqd	=> $tqd,			# our comm. channel
		_isa	=> \@isa,			# classes in hierarchy of proxied object
		_can	=> \%can,			# exported methods of proxied object
		_timeout => $timeout,		# TQD timeout
		_server_tid => $tid,		# tid of apartment thread
	);
	bless \%self, $class;
#
#	if we have the $method, then we should proceed to
#	install all the exported methods into our object
#
	return \%self;
}
#/**
# Overload UNIVERSAL::isa() to test the class hierarchy of the proxied object.
#
# @param $class		class to check if implemented by the proxied object
#
# @return		1 if the proxied object implements $class; undef otherwise
#*/
sub isa {
	my ($self, $class) = @_;
#
#	catch stuff we need to expose for queueing purposes
#
	return 1
		if (($class eq 'Thread::Queue::Queueable') ||
			($class eq 'Thread::Queue::TQDContainer') ||
			($class eq 'Thread::Apartment::Client'));
	foreach (@{$self->{_isa}}) {
		return 1 if ($_ eq $class);
	}
	return undef;
}

#/**
# Overload UNIVERSAL::can() to test the available methods of the proxied object.
#
# @param $method	method to check if implemented by the proxied object
#
# @return		if the proxied object exports $method (or exports AUTOLOAD),
#				a closure forcing an AUTOLOAD of the specified $method; undef otherwise
#*/
sub can {
	my ($self, $method) = @_;
#
#	we may need to trap the methods for TQQ here...
#	NOTE!!! Need to return a coderef here!!!
#
	return ((exists $self->{_can}{$method}) ||
		(exists $self->{_can}{'*'}) ||
		(exists $self->{_can}{AUTOLOAD})) ?
		sub { $AUTOLOAD = $method; return $self->AUTOLOAD(@_); } :
		undef;
}
#/**
# Test if the specified method is exported as simplex
#
# @param $method method to test for simplex behavior
#
# @return		1 if $method is exported and is simplex; undef otherwise
#*/
sub ta_is_simplex {
	return (exists $_[0]->{_can}{$_[1]} ?
		($_[0]->{_can}{$_[1]} & TA_SIMPLEX) : undef);
}

#/**
# Test if the specified method is exported as urgent
#
# @param $method method to test for urgent behavior
#
# @return		1 if $method is exported and is urgent; undef otherwise
#*/
sub ta_is_urgent {
	return (exists $_[0]->{_can}{$_[1]} ?
		($_[0]->{_can}{$_[1]} & TA_URGENT) : undef);
}

#/**
# Set debug level. When set to a "true" value, causes the TAC to emit
# diagnostic information.
#
# @param $level	debug level. zero or undef turns off debugging; all other values enable debugging
#
# @return		the new level
#*/
sub tac_debug { $_[0]->{_tac_debug} = $_[1]; }

sub AUTOLOAD {
#
#	called in client stub
#	passes method name
#	if starts w/ ta_async_, then return immediately
#	if starts w/ ta_reentrant_, or local thread's T::A::is_reentrant
#		is true, interleave local thread inbound calls
#		while waiting for method results
#	NOTE: use explicit substr() instead of regex for performance
#
	my $self = shift;

	my $method = $AUTOLOAD;

	print STDERR "TAC::AUTOLOAD: Method is $method\n"
		if (substr($method, -9) ne '::DESTROY') && $self->{_tac_debug};

	$async_method = undef,
	return 1
		if (substr($method, -9) eq '::DESTROY');
#
#	get rid of leading stuff
#
#warn "requested method $method\n";
	$method = substr($method, TAC_CLASS_LEN)
		if (substr($method, 0, TAC_CLASS_LEN) eq 'Thread::Apartment::Client::');

	my $tid = threads->self()->tid();

	my $async;
	my $reentrant = Thread::Apartment::get_reentrancy();
	if (substr($method, 0, TAC_ASYNC_LEN) eq 'ta_async_') {
		$method = substr($method, TAC_ASYNC_LEN);
		$@ = "No response closure supplied for async method $method.",
		$async_method = undef,
		return undef
			unless $_[0] && (ref $_[0]) && (ref $_[0] eq 'CODE');

		$async = 1;
#		$method = defined($1) ? "$1$2" : $2;
	}
	elsif (substr($method, 0, TAC_REENT_LEN) eq 'ta_reentrant_') {
		$reentrant = 1;
		$method = substr($method, TAC_REENT_LEN);
#		print STDERR "Got re-entrant call to $method\n";
	}

	unless (($method eq 'ta_invoke_closure') ||
		(exists $self->{_can}{$method}) ||
		(exists $self->{_can}{'AUTOLOAD'})) {
		$@ = "Can't locate method \"$method\" via package \"$self->{_class}\"";
		print STDERR $@, "\n"
			if $self->{_tac_debug};
		$async_method = undef;
		return undef;
	}
#	print STDERR "Client objid is $self->{_id}\n"
#		if exists $self->{_can}{'AUTOLOAD'};
#
#	support simplex/urgent specification
#
	my $flag = $self->{_can}{$method} || 0;
#
#	including for closures
#	check for default closure call behaviors;
#	note that these are cumulative
#
#print "Simplex is ", TA_SIMPLEX, " urgent is ", TA_URGENT, "\n";
	$_[1] |= Thread::Apartment::get_closure_behavior(),
	$flag = ($_[1] & (TA_SIMPLEX | TA_URGENT))
		if ($method eq 'ta_invoke_closure');

	my @params = ($async && (!$async_method)) ?
		('ta_async', $self->{_id}, wantarray, $method) :
		($method, $self->{_id}, wantarray);
#
#	marshal params
#	(assume the TAS implementation has a complementary unmarshal)
#
#	print join(', ', @_), "\n"
#		if (scalar @_) && ($method eq 'ta_invoke_closure');
	push @params, $self->marshal(@_)
		if scalar @_;

	my $tqd = $self->{_tqd};			# perf opt.
	my $timeout = $self->{_timeout};	# perf opt.
#
#	don't support start()/rendezvous() for simplex
#
	$async_method = undef,
	return (($flag & TA_URGENT) ?
		$tqd->enqueue_simplex_urgent(@params) :
		$tqd->enqueue_simplex(@params))
		if ($flag & TA_SIMPLEX);

#print STDERR "calling getCase in $tid\n" if ($method eq 'getCase');

#print STDERR "calling $method with ", join(', ', @params), "\n"
#	if $async;
	my $id = ($flag & TA_URGENT) ?
		$tqd->enqueue_urgent(@params) :
		$tqd->enqueue(@params);
#
#	NOTE: we don't support ta_async_ w/ start()/rendezvous()
#
	$async_method = undef,
#	print STDERR "Called async method $method\n" and
	return $id
		if $async;

	Thread::Apartment->map_async_request_id($async_method, $self, $id),
	$async_method = undef,
	return $id
		if $async_method;

#print STDERR "called getCase in $tid\n" if ($method eq 'getCase');
#
#	if reentrant, attempt to service inbound calls to the caller
#	while we wait for the response...
#	note that the return value doesn't matter, since the subsequent
#	wait()'s will retrieve any pending response if the caller is
#	a TAS, or will just do the usual wait() thing if the caller
#	isn't TAS (i.e., run_wait returns undef)
#
	if ($reentrant) {
#		print STDERR "Calling T::A::run_wait in $tid for id $id at ", time(), "\n";

#		print STDERR "Returned from T::A::run_wait in $tid for timed out\n" and
		return undef
			unless Thread::Apartment::run_wait($tqd, $id, $timeout);
#		print STDERR "Returned from T::A::run_wait in $tid for id $id at ", time(), "\n";
	}

#print STDERR "waiting for getCase in $tid\n" if ($method eq 'getCase');

	my $resp = $timeout ?
		$tqd->wait_until($id, $timeout) :
		$tqd->wait($id);

#print STDERR "getCase returned in $tid\n" if ($method eq 'getCase');

#	warn "\nwait failed: $@\n" and
	return undef
		unless $resp;

	unless (defined($resp->[0])) {
		$@ = $resp->[1];
		print STDERR $@, "\n"
			if $self->{_tac_debug};
		return undef;
	}

#warn "got response: $$results[0]\n";
#	shift @$results;
#
#	unmarshal results
#
	my $results = $self->unmarshal($resp->[0]);

	return wantarray ? @$results : defined(wantarray) ? $results->[0] : 1;
}

#/**
# Return current TQD timeout
#
# @return		TQD timeout in seconds
#*/
sub get_timeout {
	return $_[0]->{_timeout};
}

#/**
# Return proxied class
#
# @return		proxied class name string
#*/
sub get_proxied_class {
	return $_[0]->{_class};
}

#/**
# Set TQD timeout
#
# @param $timeout	max. number of seconds to wait for TQD responses.
#
# @return		previous timeout value
#*/
sub set_timeout {
	my $to = $_[0]->{_timeout};
	$_[0]->{_timeout} = $_[1];
	return $to;
}
#/**
# Wait for the proxied object's apartment thread to exit.
#
# @return		1
#*/
sub join {
#
#	Don't know why, but unless we use the scalar TID
#	instead of deref'ing, object() just won't work ???
#
	my $tid = $_[0]->{_server_tid};

#print STDERR "Joining $tid\n";
	my $thread = threads->object($tid);
#print STDERR "Thread $tid not found\n" and
	return 1
		unless $thread;
	$thread->join();
#print STDERR "Joined...$tid\n";
	return 1;
}

#/**
# Stop the proxied object's apartment thread.
#*/
sub stop {
	$_[0]->{_tqd}->enqueue_simplex('STOP');
}
#/**
# TQQ redeem() override. Checks if the TAC has been passed into
# the thread in which is was created, in which case it looks up
# and returns the proxied object in the T::A object map. Otherwise, just
# blesses the object back into a TAC.
#
# @param $class	our TAC class
# @param $obj   the object to be redeem()ed
#
# @return		if in the originating thread, the proxied object; else a
#				reblessed TAC.
#*/
sub redeem {
	my ($class, $obj) = @_;

	bless $obj, $class;
	return ($obj->{_server_tid} == threads->self()->tid()) ?
		Thread::Apartment::get_object_by_id($obj->{_id}) : $obj;
}
#/**
# Return results of a pending method/closure request.
# Looks up the pending request ID in the current thread's T::A,
# then waits for the completion of the request, unmarshals and returns
# the results.
#
# @return		results of the currently pending request (if any)
#*/
sub get_pending_results {
	my $self = shift;
	my $id = Thread::Apartment->get_pending_request($self);
	return undef unless $id;
	my @results = $self->{_tqd}->wait($id);
	return @results;
}
#/**
# Set async method for next call in current thread.
#
# @param $async	boolean value to set $async_method flag
#
# @return		none
#*/
sub set_async { $async_method = $_[0]; }

1;
