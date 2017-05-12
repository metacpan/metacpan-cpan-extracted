#/**
# Provides apartment threading wrapper to encapsulate Perl objects
# in their own apartment thread.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
# @exports start	async method/closure request method
# @exports rendezvous method to wait for completion of async method/closure calls
# @exports rendezvous_any method to wait for completion of async method/closure calls
# @exports rendezvous_until method to wait for completion of async method/closure calls
# @exports rendezvous_any_until method to wait for completion of async method/closure calls
#*/
package Thread::Apartment;
#
#	encapsulates an object in an apartment thread
#
#		new($class, @args) :
#	my $obj = Thread::Apartment->new(
#		AptClass => 'MyClass',
#		AptTimeout => $timeout,
#		AptQueue => $tqd,
#		...args...
#
#	);
#
use threads;
use threads::shared;
use Time::HiRes qw(time sleep);
use Exporter;
use Thread::Queue::Duplex;
use Thread::Apartment::Server;
use Thread::Apartment::Closure;
use Thread::Apartment::Common;
use Thread::Apartment::Common qw(:ta_method_flags);

use base('Exporter');

@EXPORT = qw(start rendezvous rendezvous_any
	rendezvous_until rendezvous_any_until);

@EXPORT_OK = qw(
	set_single_threaded
	get_object_by_id
	get_tac_for_object
	destroy_object
	add_object_reference
	add_mapped_object
	alloc_mapped_object
	get_object_methods
	evict_objects
	register_closure
	get_closure
	get_reentrancy
	set_reentrancy
	set_ta_debug
);

#
#	class method for collecting class hierarchy and
#	available methods of an object
#
use strict;
use warnings;

our %apt_pool : shared = ();	# thread pool (maps TIDs to TQDs)
our @apt_tids : shared = ();	# TIDs of free threads
our $ta_debug : shared;	# global debug flag

our %closure_map = ();			# map ids to closures
our $next_closure_id = 0;		# closure ID generator
our $closure_signature = 0;		# closure validity test
our $closure_tac;				# a special TAC to handle closures
our $is_reentrant = undef;		# 1 => permit inbound calls during wait
our $autoload_all = undef;		# 1 => export any method
our $closure_calls = undef;		# TA_SIMPLEX | TA_URGENT => set default closure call behavior
#
#	object hierarchy maps
#
our %objmap = ();
our @objidmap = ();
our @objrefcnts = ();
#
#	start/rendezvous maps
#
our %tacmap = ();

#END {
#
#	run down any threads left in the pool
#
#warn "Thread::Apartment ENDing in thread ", threads->self()->tid(), "\n";
#	{
#	lock(%apt_pool);
#	$_->enqueue_simplex('STOP')
#		foreach (values %apt_pool);
#	sleep 1;
#	foreach (keys %apt_pool) {
#		threads->object($_)->join()
#			if threads->object($_);
#	}
#	}
#};


our $VERSION = '0.51';

our $single_threaded;		# when set, we fallback to normal behavior
#
#	clear out closures and object heirarchies when cloned
#
#/**
# ithreads CLONE() method to cleanup context when a new thread is spawned.
#*/
sub CLONE {
	%closure_map = ();
	$next_closure_id = 0;
	$closure_signature = 0;
	$closure_tac = undef;
	%objmap = ();
	@objidmap = ();
	@objrefcnts = ();
	%tacmap = ();
}

#/**
# Factory constructor. Creates a factory object
# for Thread::Apartment (useful for apps which
# may subclass T::A in future)
#
# @static
# @return		T::A object
#*/
sub get_factory {
	return bless [], $_[0];
}

#/**
#
# Thread governor for installed objects
#
# @static
# @return		1
#*/
sub run {
	$@ = 'No installed object.',
	return undef
		unless $objidmap[1];

	return _run($objmap{$objidmap[1][0]}->get_queue(), 1, $objidmap[1][0]);
}
#
#	internal thread governor
#
sub _run {
	my ($cmdq, $takeQ, $tas) = @_;
#
#	manufacture our TQD for return to the caller
#	unless $takeQ indicates we should take the provided
#	queue (which is the T::A->new() constructor)
#
	my $tqd = $takeQ ? $cmdq : Thread::Queue::Duplex->new(ListenerRequired => 1);
	$tqd->listen();
	$cmdq->enqueue_simplex(threads->self()->tid(), $tqd)
		unless $takeQ;
	my $tid = threads->self()->tid();
#
#	NOTE: we must explicitly init these to undef due to threads::shared
#	bugs
#
	my ($installed, $class, $req, $isa, $methods, $is_evt, $is_mux, $is_tas, $tac) =
		(undef, undef, undef, undef, undef, undef, undef, undef, undef);
	my ($id, $method, $objid, $wantary, $obj) = (undef, undef, undef, undef, undef);
	my ($simplex, $async, $sig, $cid) = (undef, undef, undef, undef);
	my $ta_debug = undef;
#
#	create closure for responses; we'll switch between this
#	and any async respons closure
#
	my $tqdresp = sub { $tqd->respond(@_); };
	my $respmeth = undef;
	my @resp = ();
	my $resp = undef;
#
#	init object hierarchy map
#
	if ($tas) {
		$installed = 1;
		$class = ref $tas;
		$is_tas = $tas->isa('Thread::Apartment::Server');
		$is_evt = $tas->isa('Thread::Apartment::EventServer');
		$is_mux = $tas->isa('Thread::Apartment::MuxServer');
		$tac = $tas->get_client();
	}
	else {
		%objmap = ();		# from object to ID
		@objidmap = ();		# from ID to object
		@objrefcnts = ();	# object ID to refcount map
	}

#print STDERR "Thread::Apartment::run started in thread $tid\n";
	while (1) {
#
#	type of dequeue depends on type of root object
#	!!!NOTE: need to break this down and move into TAS
#	so that e.g. Perl/Tk can interleave TQD polling with
#	MainLoop (i.e., invert control flow)!!!
#
		if ($is_evt) {
			print STDERR "Polling Event server\n"
				if $ta_debug;

			$req = $tqd->dequeue_nb();
			$tas->poll(),
			next
				unless $req;
		}
		elsif ($is_mux) {
			print STDERR "Starting Mux server\n"
				if $ta_debug;

			my $vacated = $tas->run();
#
#	on return, we need to re-init
#
			$is_tas = $is_evt = $is_mux = undef;
			$tas = undef;
			%objmap = ();
			@objidmap = ();
			@objrefcnts = ();
			return 1
				if $installed;

#			print STDERR "leaving apt\n" and
			last unless $vacated;

			next;
		}
		else {
			$req = $tqd->dequeue();
		}

#print STDERR "Thread::Apartment::run got request in thread $tid\n";

		if ($req->[1] eq 'STOP') {
#
#	give object a chance to rundown
#
#print STDERR "Stopping $tid...\n";
			if ($tas) {
				$tas->evict()
					if $is_tas;
#print STDERR "Evicted $tid...\n";
				$tas = undef;
				%objmap = ();
				@objidmap = ();
				@objrefcnts = ();
			}
			last;
		}
#
#	must be function call
#
		$id = shift @$req;

		$method = shift @$req;
		($objid, $wantary) = ($method eq 'ta_install') ?
			(undef, undef) : (shift @$req, shift @$req);
#
#	create and install new instance of the class
#
		($tas, $class, $is_tas, $is_evt, $is_mux) = _ta_install($tqd, $req, $id),
		next
			if ($method eq 'ta_install');
#
#	if we're DESTROY'd, post error
#
		$tqd->respond($id, undef, "Apartment threaded $class object has been evicted."),
		next
			if (! $tas) && $class && $id;
#
#	if we're new and empty, post error
#
		$tqd->respond($id, undef, "Apartment thread is empty."),
		next
			if (! $tas) && $id;
#
#	if unknown object id, post error
#
		$tqd->respond($id, undef, "Unknown object (ID $objid)."),
		next
			unless $objidmap[$objid];
#
#	check for ref count (this is simplex)
#
		$objrefcnts[$objid]++,
		next
			if ($method eq '_add_ref');

		if ($method eq 'DESTROY') {
#
#	only destroy when refcount <= 0
#	also a simplex method
#
#print STDERR "DESTROYing\n";
			$objrefcnts[$objid]--;
			if ($objrefcnts[$objid] <= 0) {
				$objrefcnts[$objid] = 0;
				delete $objmap{$objidmap[$objid][0]};
				$objidmap[$objid] = undef;
				if ($objid == 1) {
					free_thread();
					$tas = undef;
					return 1
						if $installed;
				}
			}
			next;
		}
#
#	permits the object to be forced out, wo/ regard to objrefcnts
#
		if ($method eq 'evict') {
			$tas->evict()
				if $is_tas;
			%objmap = ();
			@objidmap = ();
			@objrefcnts = ();
			$tas = undef;
			return 1
				if $installed;
			next;
		}
#
#	verify method
#
		$respmeth = $tqdresp;
		$methods = $objidmap[$objid][2];
		$tqd->respond($id, undef, "Unknown method $method."),
		next
			unless ($method eq 'ta_async') ||
				($method eq 'ta_invoke_closure') ||
				(exists $methods->{$method}) ||
				(exists $methods->{AUTOLOAD});

		$async = undef;
		@resp = ();
		$async = 1,
		$method = shift @$req
			if ($method eq 'ta_async');
#
#	unmarshal args
#
		$req = scalar @$req ?
			($is_tas ?
				$tas->unmarshal($req->[0]) :
				Thread::Apartment::Server->unmarshal($req->[0])) :
				[];

		if ($async) {
#
#	async method call
#
			$respmeth = $req->[0];
			print STDERR "T::A::run: async call on $method with respmethod $respmeth\n"
				if $ta_debug;

			$tqd->respond($id, undef, "No closure provided for async call to $method."),
			next
				unless $respmeth && (ref $respmeth) && (ref $respmeth eq 'CODE');

			$respmeth->($id, undef, "Unknown method $method."),
			next
				unless (exists $methods->{$method}) ||
					(exists $methods->{AUTOLOAD});

			print STDERR "T::A::run: valid async call on $method \n"
				if $ta_debug;
		}

		$simplex = (exists $methods->{$method}) ?
			($methods->{$method} & TA_SIMPLEX) : 0;

		if ($method eq 'ta_invoke_closure') {
#
#	closure call
#	verify the signature and the ID
#	then call the closure
#
			($sig, $cid) = (shift @$req, shift @$req);

			$simplex = $cid & TA_SIMPLEX,
			$cid &= 0xFFFFFFFC
				if $cid;	# clear behavior bits

			print STDERR "T::A::run: calling closure $cid for sig $sig\n"
				if $ta_debug;

			$respmeth->($id, undef, "Stale closure call to thread $tid."),
			next
				unless $sig && $cid && ($sig == $closure_signature) && $closure_map{$cid};

			$cid &= 0xFFFFFFFC;	# remove flags values
#	print STDERR "Invoking closure w/ ", join(', ', @$req), "\n";

			if ($wantary) {
				@resp = $closure_map{$cid}->(@$req);
			}
			elsif (defined($wantary)) {
				$resp[0] = $closure_map{$cid}->(@$req);
			}
			else {
				$closure_map{$cid}->(@$req);
				$resp[0] = 1;
			}

			print STDERR "T::A::run: returned from $method on object $objid\n"
				if $ta_debug;
		}
		else {
			print STDERR "T::A::run: calling $method on object $objid\n"
				if $ta_debug;

			$obj = $objidmap[$objid][0];

			if ($wantary) {
				@resp = $obj->$method(@$req);
			}
			elsif (defined($wantary)) {
				$resp[0] = $obj->$method(@$req);
			}
			else {
				$obj->$method(@$req);
				$resp[0] = 1;
			}

			print STDERR "T::A::run: returned from $method on object $objid\n"
				if $ta_debug;
		}
#
#	if simplex, we're done
#
		@resp = (),	# just to GC any results
		next
			if $simplex;
#
#	now return results
#	check for errors
#
#		print STDERR "T::A::_run: async response has error \n"
#			unless (!$async) || defined($resp[0]);

		$resp[1] = $@,
		$respmeth->($id, @resp),
		next
			unless defined($resp[0]);
#
#	marshal the results per TAS's methods and return
#	(presumes that the TAC implements a complementary unmarshal)
#	NOTE: TAS marshal scans for new objects, and creates/registers
#	TACs for them
#
#	no marshalling of async responses, since the proxied closure will
#	marshall for us
#
		$resp = $tas->isa('Thread::Apartment::Server') ?
			$tas->marshalResults(@resp) :
			Thread::Apartment::Server->marshalResults(@resp)
			unless $async;

		$async ? $respmeth->(@resp) : $respmeth->($id, $resp);

		print STDERR ($async ?
			"T::A::_run: async response for $method on object $objid\n" :
			"T::A::run: responding for $method on object $objid\n")
			if $ta_debug;

	}	# end while not STOP

	$tqd->ignore();
	remove_thread();
#print STDERR "Returning from _run $tid...\n";
	return 1;
}
#/**
# Intermediate thread governor for re-entrant method calls.
# Used when an object has made a call on another proxied object,
# but needs to be able to service external calls to itself until
# the pending call completes.
# <p>
# Relies on the threads::shared nature of the thread pool
# map to recover the TQD for the thread in which the re-entrant call
# is made, <b>and</b> the <b>non-</b>threads::shared nature of the
# proxied object map to recover the root object.
#
# @static
# @param $pendingq	TQD of the proxied object with a pending call
# @param $call_id	request ID of the pending call
# @param $timeout	(optional) max. number of seconds to wait for an event
#
# @return		undef if timeout expires before the pending call returns,
#				or if a STOP, DESTROY on the root object, or evict()
#				call is received. 1 otherwise.
#*/
#
sub run_wait {
	my ($pendingq, $call_id, $timeout) = @_;
#
#	check that we're running in a TAS
#
	my $tid = threads->self()->tid();
	my $tqd;
	{
		lock(%apt_pool);
		$tqd = $apt_pool{$tid}
			if exists $apt_pool{$tid};
	}
#
#	we must not be a TAS, so just let TAC finish the job
#
#	print STDERR "We're not in a TAS in $tid!!!\n" and
	return 1 unless $tqd;

#	print STDERR "pendingq $pendingq call id $call_id our tqd $tqd\n";
#
#	get our root object, just in case
#
	my $tas = $objidmap[1][0];
	my $is_tas = $tas->isa('Thread::Apartment::Server');
#
#	NOTE: we must explicitly init these to undef due to threads::shared
#	bugs
#
	my ($req, $isa, $methods, $tac) = (undef, undef, undef, undef);
	my ($id, $method, $objid, $wantary, $obj) = (undef, undef, undef, undef, undef);
	my ($simplex, $async, $sig, $cid) = (undef, undef, undef, undef);
	my $ta_debug = undef;
#
#	create closure for responses; we'll switch between this
#	and any async respons closure
#
	my $tqdresp = sub { $tqd->respond(@_); };
	my $respmeth = undef;
	my @resp = ();
	my $resp = undef;
	my $expires = $timeout ? time() + $timeout : -1;
	my @ready = ();
	my $qwait;

	print STDERR "Thread::Apartment::run_wait in thread $tid\n"
		if $ta_debug;

	while (($expires == -1) || ($expires > time())) {
#
#	unlike _run(), we always handle our own wait, and use the
#	static version
#
		@ready = $timeout ?
			Thread::Queue::Duplex->wait_any_until($expires - time(), $tqd, [ $pendingq, $call_id ]) :
			Thread::Queue::Duplex->wait_any($tqd, [ $pendingq, $call_id ]);

#print STDERR "Thread::Apartment::run_wait got response to pending call in thread $tid\n" and
	return 1 if $pendingq->ready($call_id);
#
#	something untoward happened, so just exit
#
#		return undef
#			unless @ready;
#
#	check if the pending call has returned
#
#		return 1
#			if ($ready[0] eq $pendingq) ||
#				($ready[1] && ($ready[1] eq $pendingq));
#
#	else fetch a request from our queue
#
		$req = $tqd->dequeue_nb();

		next
			unless $req;

		if ($req->[1] eq 'STOP') {
#
#	retrieve our root object from the class variable
#	and give it a chance to rundown
#	lord only knows what sort of mayhem may result...
#
			print STDERR "Stopping $tid...\n"
				if $ta_debug;
			if ($tas) {
				$tas->evict() if $is_tas;
				print STDERR "Evicted $tid...\n"
					if $ta_debug;
				%objmap = ();
				@objidmap = ();
				@objrefcnts = ();
			}
			return undef;
		}
#
#	must be function call
#
		$id = shift @$req;

		$method = shift @$req;
		$tqd->respond($id, undef, "Apartment thread already occupied."),
		next
			if ($method eq 'ta_install');

		($objid, $wantary) =  (shift @$req, shift @$req);
#
#	if unknown object id, post error
#
		$tqd->respond($id, undef, "Unknown object (ID $objid)."),
		next
			unless $objidmap[$objid];
#
#	check for ref count (this is simplex)
#
		$objrefcnts[$objid]++,
		next
			if ($method eq '_add_ref');

		if ($method eq 'DESTROY') {
#
#	only destroy when refcount <= 0
#	also a simplex method
#	once again, this is likely to end badly if called on root thread
#
			print STDERR "DESTROYing\n"
				if $ta_debug;

			$objrefcnts[$objid]--;
			next if ($objrefcnts[$objid] > 0);

			$objrefcnts[$objid] = 0;
			delete $objmap{$objidmap[$objid][0]};
			$objidmap[$objid] = undef;

			free_thread(),
			return undef
				if ($objid == 1);
			next;
		}
#
#	permits the object to be forced out, wo/ regard to objrefcnts
#	yet again, this is likely to end badly
#
		if ($method eq 'evict') {
			$tas->evict() if $is_tas;
			%objmap = ();
			@objidmap = ();
			@objrefcnts = ();
			return undef;
		}
#
#	verify method
#
		$respmeth = $tqdresp;
		$methods = $objidmap[$objid][2];
		$tqd->respond($id, undef, "Unknown method $method."),
		next
			unless ($method eq 'ta_async') ||
				($method eq 'ta_invoke_closure') ||
				(exists $methods->{$method}) ||
				(exists $methods->{AUTOLOAD});

		$async = undef;
		@resp = ();
		$async = 1,
		$method = shift @$req
			if ($method eq 'ta_async');
#
#	unmarshal args
#
		$req = scalar @$req ?
			($is_tas ?
				$tas->unmarshal($req->[0]) :
				Thread::Apartment::Server->unmarshal($req->[0])) :
				[];

		if ($async) {
#
#	async method call
#
			$respmeth = $req->[0];
			print STDERR "T::A::run_wait: async call on $method with respmethod $respmeth\n"
				if $ta_debug;

			$tqd->respond($id, undef, "No closure provided for async call to $method."),
			next
				unless $respmeth && (ref $respmeth) && (ref $respmeth eq 'CODE');

			$respmeth->($id, undef, "Unknown method $method."),
			next
				unless (exists $methods->{$method}) ||
					(exists $methods->{AUTOLOAD});

			print STDERR "T::A::run_wait: valid async call on $method \n"
				if $ta_debug;
		}

		$simplex = (exists $methods->{$method}) ?
			($methods->{$method} & TA_SIMPLEX) : 0;

		if ($method eq 'ta_invoke_closure') {
#
#	closure call
#	verify the signature and the ID
#	then call the closure
#
			($sig, $cid) = (shift @$req, shift @$req);

			print STDERR "T::A::run_wait: calling closure $cid\n"
				if $ta_debug;

			$respmeth->($id, undef, "Stale closure call to thread $tid."),
			next
				unless $sig && $cid && ($sig == $closure_signature) && $closure_map{$cid};

			$simplex = $cid & TA_SIMPLEX;
			$cid &= 0xFFFFFFFC;

			print STDERR "Invoking closure w/ ", join(', ', @$req), "\n"
				if $ta_debug;

			if ($wantary) {
				@resp = $closure_map{$cid}->(@$req);
			}
			elsif (defined($wantary)) {
				$resp[0] = $closure_map{$cid}->(@$req);
			}
			else {
				$closure_map{$cid}->(@$req);
				$resp[0] = 1;
			}

			print STDERR "T::A::run_wait: returned from $method on object $objid\n"
				if $ta_debug;
		}
		else {
			print STDERR "T::A::run_wait: calling $method on object $objid\n"
				if $ta_debug;

			$obj = $objidmap[$objid][0];

			if ($wantary) {
				@resp = $obj->$method(@$req);
			}
			elsif (defined($wantary)) {
				$resp[0] = $obj->$method(@$req);
			}
			else {
				$obj->$method(@$req);
				$resp[0] = 1;
			}

			print STDERR "T::A::run_wait: returned from $method on object $objid\n"
				if $ta_debug;
		}
#
#	if simplex, we're done
#
		@resp = (),	# just to GC any results
		next
			if $simplex;
#
#	now return results
#	check for errors
#
#		print STDERR "T::A::run_wait: async response has error \n"
#			unless (!$async) || defined($resp[0]);

		$resp[1] = $@,
		$respmeth->($id, @resp),
		next
			unless defined($resp[0]);
#
#	marshal the results per TAS's methods and return
#	(presumes that the TAC implements a complementary unmarshal)
#	NOTE: TAS marshal scans for new objects, and creates/registers
#	TACs for them
#
#	no marshalling of async responses, since the proxied closure will
#	marshall for us
#
		$resp = $is_tas ?
			$tas->marshalResults(@resp) :
			Thread::Apartment::Server->marshalResults(@resp)
			unless $async;

		$async ? $respmeth->(@resp) : $respmeth->($id, $resp);

		print STDERR ($async ?
			"T::A::run_wait: async response for $method on object $objid\n" :
			"T::A::run_wait: responding for $method on object $objid\n")
			if $ta_debug;

	}	# end while not timeout

	print STDERR "T::A::run_wait expired in thread $tid...\n"
		if $ta_debug;

	$@ = 'run_wait() expired.';
	return undef;
}
#/**
# Stop and remove a thread
#
# @simplex
#
# @return		The object
#*/
sub stop {
	$_[0]->{_tqd}->enqueue_simplex('STOP');
	return $_[0];
}

#/**
# Class method to force single threading.
# Note that this behavior is irreversible.
#
# @static
# @return		nothing
#*/
sub set_single_threaded {
	$single_threaded = 1;
}

#/**
# Constructor. Factory method to create an instance of a class in an
# apartment thread. Produces a client proxy version as the return
# value. If <a href="#set_single_threaded">set_single_threaded()</a>
# has been called, then acts as a simple factory returning an instance
# of the class without installing in an apartment thread (useful for
# debugging purposes).
# <p>
# The caller may supply a <a href='http://search.cpan.org/perldoc?Thread::Queue::Duplex'>TQD</a>
# (<i> and hence, the apartment thread</i>)
# to be used as the communications channel between the apartment thread and client proxy instances.
# If not provided, either a thread and TQD are allocated from the existing pool
# (see <a href="#create_pool">create_pool()</a>), or, if no pooled threads
# are available, a new apartment thread and TQD are created, in which to install the created object.
# By supplying a TQD, the application can create a pool
# of threads and TQDs as early as possible with the least context neccesary, and then
# allocate them to apartment threads as needed. However, the
# <a href="#create_pool">create_pool()</a> method may be simpler for most applications.
# <p>
# Some default behaviors of the object(s) created/installed in the apartment thread may be
# directed using the AptReentrant, AptAutoload, or AptClosureCalls parameters
# <i>(see below)</i>.
#
# @static
# @param AptClass	class to be instantiated into an apartment thread
# @param AptMaxPending	(optional) passed throught to any TQD created for the thread
# @param AptQueue	(optional) <a href='Thread_Queue_Duplex.html'>Thread::Queue::Duplex</a>
#					to be used to communicate to the proxied object(s)
# @param AptTimeout (optional) timeout (in seconds) for responses to any non-simplex
#					proxied method call.
# @param AptParams  (optional) arrayref or hashref of parameters required for the proxied
#					class's constructor (if the object requires something other than
#					a hash for constructor parameters)
# @param AptReentrant  (optional) boolean indicating whether the objects in the apartment
#					thread should permit re-entrancy (i.e., handle inbound method calls)
#					while waiting for the results of outbound calls to other T::A objects;
#					default is undef (false).
# @param AptAutoload  (optional) boolean indicating whether the objects in the apartment
#					thread should permit <i>any</i> method call, rather than be restricted
#					to introspected, public methods. Default is undef (false).
# @param AptClosureCalls  (optional) scalar string, or arrayref of strings, indicating whether
#					proxied closures called from objects in the apartment
#					should be treated as 'Simplex', 'Urgent', or both.
#					Default is undef (duplex, non-urgent). Valid (case-insensitive) values
#					are 'Simplex', 'Urgent', or an arrayref containing either or both of
#					those values.
#
# @return		<a href='./Apartment/Client.html'>Thread::Apartment::Client</a> object
#*/
sub new {
	my ($class, %args) = @_;

	$@ = 'Thread::Apartment::new: no AptClass specified',
	return undef
		unless $args{AptClass};

	$class = $args{AptClass};
#
#	if we're single threaded, invoke constructor directly
#
	if ($single_threaded) {
		eval "require $class;";
		return undef if $@;
		delete $args{AptClass};
		return ${class}->new(%args);
	}

	my $cmdq = $args{AptQueue};
	$@ = 'Thread::Apartment::new: AptQueue is not a Thread::Queue::Duplex.',
	return undef
		if ($cmdq && (!$cmdq->isa('Thread::Queue::Duplex')));
#
#	validate/convert AptClosureCalls
#
	my $closures = $args{AptClosureCalls};
	if ($closures) {
		my $flags = 0;
		if (ref $closures) {
			$@ = 'Thread::Apartment::new: Invalid value for AptClosureCalls.',
			return undef
				unless (ref $closures eq 'ARRAY');
			foreach (@$closures) {
				$@ = 'Thread::Apartment::new: Invalid value for AptClosureCalls.',
				return undef
					unless ((lc $_ eq 'simplex') || (lc $_ eq 'urgent'));
				$flags |= (lc $_ eq 'simplex') ? TA_SIMPLEX : TA_URGENT;
			}
		}
		else {
			$@ = 'Thread::Apartment::new: Invalid value for AptClosureCalls.',
			return undef
				unless ((lc $_ eq 'simplex') || (lc $_ eq 'urgent'));
			$flags = (lc $_ eq 'simplex') ? TA_SIMPLEX : TA_URGENT;
		}
		$args{AptClosureCalls} = $flags;
	}
#
#	check for thread pool
#
	unless ($cmdq) {
		lock(%apt_pool);
#
#	since threads can be removed, we need to shift thru the list
#
		while (scalar @apt_tids) {
			my $tid = shift @apt_tids;
			$cmdq = $apt_pool{$tid},
			last
				if exists $apt_pool{$tid};
		}
		unless ($cmdq) {
			$cmdq = Thread::Queue::Duplex->new(
				ListenerRequired => 1,
				MaxPending => $args{AptMaxPending}),
			my $thread = threads->create(\&_run, $cmdq, 1);
			$apt_pool{$thread->tid()} = $cmdq;
		}
	}
	$cmdq->wait_for_listener();
#
#	if we have parameters, marshal them using the Common methods
#
	$args{AptParams} = (ref $args{AptParams} eq 'ARRAY') ?
		Thread::Apartment::Common->marshal(@{$args{AptParams}}) :
		Thread::Apartment::Common->marshal(%{$args{AptParams}})
		if ($args{AptParams} && ref $args{AptParams});

	my $params = Thread::Apartment::Common->marshal(%args);

	my $resp = $args{AptTimeout} ?
		$cmdq->enqueue_and_wait_until($args{AptTimeout}, 'ta_install', $params) :
		$cmdq->enqueue_and_wait('ta_install', $params);
#
#	returned value is the TAC for the object
#
	$@ = $resp->[1] unless defined($resp->[0]);
	return ($resp && $resp->[0]) ? $resp->[1] : undef;
}
#/**
# Install an object into the current thread. Similar to <a href="#new">new()</a>,
# except that the current thread is converted to an apartment thread, rather
# than creating a new thread (or allocating one from a thread pool). Useful for
# some legacy packages (e.g., <a href="http://search.cpan.org/perldoc?Tk">Perl/Tk</a>).
# <p>
# Whereas <a href='#new'>new()</a> creates a new instance of
# a class and installs it in <b>another</b> thread, which immediately begins
# monitoring the TQD channel for proxied method calls,
# <code>install()</code> creates a new instance of a class and installs it <b>in the
# current thread</b>, returning a <a href='./Apartment/Container.html'>TACo</a>,
# which references both the actual created object, <b>and</b> its TAC, so the installed object
# can be invoked within the current thread, yet still be distributed to other apartment
# threaded objects.
# <p>
# When an application needs to pass an <code>install()</code>ed object to other threads,
# it has 2 options:
# <ol>
# <li>The TAC objects to receive a reference to the installed object must be
# passed to the installed object constructor, and implement a known method which the
# installed object calls to supply its own TAC. The resulting tight coupling
# requires additional wrappers or subclassing for use by POPOs and legacy classes.
# <p>
# <li>Alternately, install() simply returns a TACo for the installed object
# (rather than its TAC, as for <a href='#new'>new()</a>), and the
# main flow of the application can distribute the TACo object to the other
# apartment threaded objects as needed. Once the installed object is fully distributed,
# and any other initialization is completed,
# the main flow simply calls <a href="#run">Thread::Apartment::run()</a> method,
# which assumes control of the current thread.
# The resulting loosely coupled component based architecture simplifies the assembly
# of apartment threaded objects, and is more easily supported by POPO's and legacy objects.
# </ol>
#
# @static
# @param AptClass	class to be instantiated into an apartment thread
# @param AptMaxPending	(optional) passed throught to any TQD created for the thread
# @param AptQueue	(optional) <a href='http://search.cpan.org/perldoc?Thread::Queue::Duplex'>Thread::Queue::Duplex</a>
#					to be used to communicate to the proxied object(s)
# @param AptTimeout (optional) timeout (in seconds) for responses to any non-simplex
#					proxied method call.
# @param AptParams  (optional) arrayref or hashref of parameters required for the proxied
#					class's constructor
# @param AptReentrant  (optional) boolean indicating whether the objects in the apartment
#					thread should permit re-entrancy (i.e., handle inbound method calls)
#					while waiting for the results of outbound calls to other T::A objects;
#					default is undef (false).
# @param AptAutoload  (optional) boolean indicating whether the objects in the apartment
#					thread should permit <i>any</i> method call, rather than be restricted
#					to introspected, public methods. Default is undef (false).
# @param AptClosureCalls  (optional) scalar string, or arrayref of strings, indicating whether
#					proxied closures called from objects in the apartment thread
#					should be treated as 'Simplex', 'Urgent', or both.
#					Default is undef (duplex, non-urgent). Valid (case-insensitive) values
#					are 'Simplex', 'Urgent', or an arrayref containing either or both of
#					those values.
#
# @return		nothing
# @returnlist	nothing
#*/
sub install {
	my ($class, %args) = @_;

	$@ = 'Thread::Apartment::install: no AptClass specified',
	return undef
		unless $args{AptClass};

	$class = $args{AptClass};
#
#	if we're single threaded, invoke constructor directly
#
	delete $args{AptClass},
	return ${class}->new(%args)
		if $single_threaded;

	my $cmdq = $args{AptQueue};
	$@ = 'Thread::Apartment::install: AptQueue is not a Thread::Queue::Duplex.',
	return undef
		if ($cmdq && (!$cmdq->isa('Thread::Queue::Duplex')));
#
#	validate/convert AptClosureCalls
#
	my $closures = $args{AptClosureCalls};
	if ($closures) {
		my $flags = 0;
		if (ref $closures) {
			$@ = 'Thread::Apartment::new: Invalid value for AptClosureCalls.',
			return undef
				unless (ref $closures eq 'ARRAY');
			foreach (@$closures) {
				$@ = 'Thread::Apartment::new: Invalid value for AptClosureCalls.',
				return undef
					unless ((lc $_ eq 'simplex') || (lc $_ eq 'urgent'));
				$flags |= (lc $_ eq 'simplex') ? TA_SIMPLEX : TA_URGENT;
			}
		}
		else {
			$@ = 'Thread::Apartment::new: Invalid value for AptClosureCalls.',
			return undef
				unless ((lc $_ eq 'simplex') || (lc $_ eq 'urgent'));
			$flags = (lc $_ eq 'simplex') ? TA_SIMPLEX : TA_URGENT;
		}
		$args{AptClosureCalls} = $flags;
	}
#
#	create queue if none provided
#
	$args{AptQueue} = $cmdq = Thread::Queue::Duplex->new(
		ListenerRequired => 1,
		MaxPending => $args{AptMaxPending})
		unless $cmdq;
#
#	map us into the thread pool
#
	{
		lock(%apt_pool);
		$apt_pool{threads->self()->tid()} = $cmdq;
	}
#
#	we're the listener...
#
	$cmdq->listen();

	return _install(%args);
}
#/**
# Create a thread pool for apartment threaded objects.
# Useful for limiting the amount of context cloned into
# apartment threads. By creating a pool of threads before
# <code>require</code>'ing any modules, the threads will
# have minimal context before the apartment thread objects
# are installed into them.
#
# @static
# @param AptMaxPending	used to set MaxPending on created <a href='http://search.cpan.org/perldoc?Thread::Queue::Duplex'>TQD's</a>.
# @param AptPoolSize    the number of threads to create in the pool
#
# @return		number of threads created
#*/
sub create_pool {
	my ($class, %args) = @_;
#
#	if we're single threaded, invoke constructor directly
#
	return 1 if $single_threaded;

	$@ = 'No AptPoolSize specified.',
	return undef
		unless $args{AptPoolSize} && ($args{AptPoolSize} > 0);

	lock(%apt_pool);
	foreach (1..$args{AptPoolSize}) {
		my $cmdq = Thread::Queue::Duplex->new(
			ListenerRequired => 1,
			MaxPending => $args{AptMaxPending});
		my $thread = threads->create(\&_run, $cmdq, 1);
		$cmdq->wait_for_listener();

		$apt_pool{$thread->tid()} = $cmdq;
		push @apt_tids, $thread->tid();
	}
	return $args{AptPoolSize};
}

#/**
# Stop and remove all threads
# @static
# @return		1
#*/
sub destroy_pool {
	my @tids = ();
	my $tid;
	my $q;
	{
		lock(%apt_pool);
		$q->enqueue_simplex('STOP'),
		push @tids, $tid
			while (($tid, $q) = each %apt_pool);
	}
#	print STDERR "Waiting for the following threads: ", join(', ', @tids), "\n";
	foreach (@tids) {
		my $thrd = threads->object($_);
		$thrd->join()
			if $thrd;
	}
#
#	when cleaned up, clear the free pool
#
	lock(%apt_pool);
	@apt_tids = ();
	return 1;
}
#/**
# Return a thread to the pool. Called within the
# thread to be returned.
#
# @static
#
# @return		1
#*/
sub free_thread {
	my $tid = threads->self()->tid();

	lock(%apt_pool);
	push @apt_tids, $tid
		if $apt_pool{$tid};
	return 1;
}
#/**
# Remove a thread from the pool. Called within the
# thread to be returned.
#
# @static
#
# @return		1
#*/
sub remove_thread {
	my $tid = threads->self()->tid();

	lock(%apt_pool);
	delete $apt_pool{$tid};
	return 1;
}
#
#	install for install()
#
sub _install {
	my %args = @_;

	$@ = 'Apartment thread already occupied.',
	return undef
		if $objidmap[1];
#
#	verify the class
#
	my $class = delete $args{AptClass};
	eval "require $class;";
	$@ = "Cannot require $class: $@",
	return undef
		if $@;
#
#	set re-entrancy
#
	$is_reentrant = $args{AptReentrant};
	$autoload_all = $args{AptAutoload};
	$closure_calls = $args{AptClosureCalls};
#
#	use local flags to optimize
#
	my $is_tas = ${class}->isa('Thread::Apartment::Server');
#
#	get any add'l params
#
	my $req = $args{AptParams};
#
#	set up thread-global variables
#
	my $timeout = delete $args{AptTimeout};
	my $tqd = $args{AptQueue};
#
#	install elements into TAS class variables
#
	Thread::Apartment::Server::init_tas($tqd, $timeout, 1);
#
#	get class's ISA and can() lists, and a TAC
#
	my ($isa, $methods, $tac) = $is_tas ?
		${class}->introspect(1) :
		Thread::Apartment::Server::introspect($class, 1);
#
#	create an instance:
#		since a TAS may need its TAC to pass to other
#		T::A objects, we need to construct it differently
#		so it generates its own TAC
#		Note that POPOs won't knowingly create T::A objects
#
	my $tas = $is_tas?
		($args{AptParams} ?
			${class}->new($tac, @$req) :
			${class}->new(AptTAC => $tac, %args)) :
		($args{AptParams} ?
			${class}->new(@$req) :
			${class}->new(%args));

	$@ ||= 'Unknown error',
	$@ = "Unable to construct a $class object: $@.",
	return undef
		unless $tas;
#
#	add object to hierarchy map
#
	$objmap{$tas} = $tac;
	$objidmap[1] = [ $tas, $isa, $methods ];
	$objrefcnts[1] = 1;

	print STDERR "_install: $class installed in thread ", threads->self()->tid(), "\n"
		if $ta_debug;
#
#	set up thread-global proxied closure members;
#	note that closure TAC is TACo
#
	%closure_map = ();
	$next_closure_id = 1;
	$closure_signature = time();
#	$closure_tac = Thread::Apartment::Container->new(-1,
#		Thread::Apartment::Client->new(
#			'Thread::Apartment::Closure', $tqd, -1, [ 'Thread::Apartment::Closure' ],
#				{ 'ta_invoke_closure' => 0 }, undef, threads->self()->tid()));

	$closure_tac = Thread::Apartment::Client->new(
			'Thread::Apartment::Closure', $tqd, -1, [ 'Thread::Apartment::Closure' ],
				{ 'ta_invoke_closure' => 0 }, undef, threads->self()->tid());

	return $tac;
}
#
#	install for new()
#
sub _ta_install {
	my ($tqd, $req, $id) = @_;
#
#	must be installing an object; note we shouldn't ever
#	get this if running an installed object
#
	my $tid = threads->self()->tid();
	$tqd->respond($id, undef, 'Apartment thread already occupied.'),
#	print STDERR "Apartment thread $tid already occupied by ", (ref $objidmap[1][0]), ".\n" and
	return undef
		if $objidmap[1];
#
#	for factory purposes, we'll use Common marshal/unmarshal
#
	$req = Thread::Apartment::Common->unmarshal(@$req);
	my %args = @$req;
	my $class = delete $args{AptClass};
	eval "require $class;";
	$tqd->respond($id, undef, "Cannot require $class: $@"),
	return undef
		if $@;
#
#	use local flags to optimize
#
	my $is_tas = ${class}->isa('Thread::Apartment::Server');
	my $is_evt = ${class}->isa('Thread::Apartment::EventServer');
	my $is_mux = ${class}->isa('Thread::Apartment::MuxServer');
#
#	check if we're to be re-entrant
#
	$is_reentrant = delete $args{AptReentrant};
	$autoload_all = delete $args{AptAutoload};
	$closure_calls = delete $args{AptClosureCalls};
#
#	if we've got any add'l params, unmarshal them
#
	$req = Thread::Apartment::Common->unmarshal($args{AptParams})
		if $args{AptParams};
#
#	in future, check if a TAC pool is requested
#
#	if ($args{AptClientPool}) {
#	}
#
#	return the class's ISA and can() lists,
#	and a TAC
#
	my $timeout = delete $args{AptTimeout};
	Thread::Apartment::Server::init_tas($tqd, $timeout, undef);

	my ($isa, $methods, $tac) = $is_tas ?
		${class}->introspect(1) :
		Thread::Apartment::Server::introspect($class, 1);
#
#	create an instance:
#		since a TAS may need its TAC to pass to other
#		T::A objects, we need to construct it differently
#		so it generates its own TAC
#		Note that POPOs won't knowingly create T::A objects
#
	my $tas = $is_tas ?
		($args{AptParams} ?
			${class}->new($tac, @$req) :
			${class}->new(AptTAC => $tac, %args)) :
		($args{AptParams} ?
			${class}->new(@$req) :
			${class}->new(%args));

	$@ ||= 'Unknown error',
	$tqd->respond($id, undef, "Unable to construct a $class object: $@."),
	return undef
		unless $tas;
#
#	add object to hierarchy map
#
	$objmap{$tas} = $tac;
	$objidmap[1] = [ $tas, $isa, $methods ];
	$objrefcnts[1] = 1;
#
#	no need to marshal, $tac is a TQQ... (and should be shared...)
#
	print STDERR "run: $class installed in thread $tid\n"
		if $ta_debug;
#
#	set up thread-global proxied closure members
#
	%closure_map = ();
	$next_closure_id = 1;
	$closure_signature = time();
	$closure_tac = Thread::Apartment::Client->new(
		'Thread::Apartment::Closure', $tqd, -1, [ 'Thread::Apartment::Closure' ],
			{ 'invoke_closure' => 0 }, undef, threads->self()->tid());

	$tqd->respond($id, 1, $tac);

	return ($tas, $class, $is_tas, $is_evt, $is_mux);
}

###########################################################
#
#	CLOSURE MGMT METHODS
#
###########################################################
#/**
# Registers a closure with the apartment thread before
# it is passed to another thread as either a parameter, or
# as a return value. Unlike a closure, the returned
# <a href='./Apartment/Closure.html'>Thread::Apartment::Closure</a> <i>aka</i>
# <b>TACl</b> object is suitable for marshalling across threads.
# <p>
# When another thread receives the TACl it will unmarshall it as
# a local closure that invokes a special method on the originating
# thread's TAC, which in turn will cause the originating thread
# to invoke the locally registered closure.
#
# @static
# @param $closure	closure to be registered
# @param $flags		bitmask of flags indicating simplex and/or urgent behavior
#					(see <a href="./Apartment/Common.html#exports">Thread::Apartment::Common</a>
#					for bitmask values)
#
# @return		<a href='./Apartment/Closure.html'>Thread::Apartment::Closure</a> object.
#*/
sub register_closure {
	my $id = ($next_closure_id++) << 2;

	$closure_map{$id} = $_[0];
	$id |= $_[1] if $_[1];
	return Thread::Apartment::Closure->new($closure_signature, $id, $closure_tac);
}

#/**
# Return the closure for a specified closure ID.
#
# @static
#
# @param $sig	closure signature (used to reject stale closures when an appartment thread is recycled)
# @param $id	closure ID
#
# @return		if the signature and ID match, the closure; undef otherwise
#*/
sub get_closure {
	my ($sig, $id) = @_;
	return ($sig && $id && ($sig == $closure_signature)) ?
		$closure_map{$id} : undef;
}
###########################################################
#
#	OBJECT HIERARCHY MGMT METHODS
#	*candidate for a separate class ?*
#
###########################################################
#/**
# Destroy a mapped object. Decrements the object's
# external reference count. If the reference count drops to
# zero, removes the object from the object map.
#
# @static
# @param $objecid	object ID
#
# @return		1 if the ID is for the root object; undef otherwise
#*/
sub destroy_object {
	my $objid = shift;
	$objrefcnts[$objid]--;
	return 1
		unless ($objrefcnts[$objid] <= 0);

	$objrefcnts[$objid] = 0;
	delete $objmap{$objidmap[$objid][0]};
	$objidmap[$objid] = undef;
	return ($objid == 1) ? undef :1;
}

#/**
# Increment the reference count for an object.
#
# @param $objid	object ID
#
# @return		the object's new reference count
#*/
sub add_object_reference { $objrefcnts[$_[0]]++; }

#/**
# Evict the current resident objects from the apartment thread.
#
# @static
#
# @return		undef
#*/
sub evict_objects {
	%objmap = ();
	@objidmap = ();
	@objrefcnts = ();
	return undef;
}

#/**
# Return the hash map of method names to simplex/urgent flags
# for a specified object ID.
#
# @static
# @param $objid	object ID
#
# @return		hashref mapping method names to behavior flags
#*/
sub get_object_methods { return $objidmap[$_[0]][2]; }

#/**
# Return the object for a specified object ID.
#
# @static
# @param $objid	object ID
#
# @return		the object
#*/
sub get_object_by_id {
	return $objidmap[$_[0]] ? $objidmap[$_[0]][0] : undef;
}

#/**
# Return the TAC for a mapped object
#
# @static
# @param $object	the object (<b>not</b> the object ID!)
#
# @return		<a href='./Apartment/Client.html'>TAC</a> for the object
#*/
sub get_tac_for_object { return $objmap{$_[0]}; }

#/**
# Add an object to the object map
#
# @static
# @param $objid	object ID
# @param $tac		the TAC (or possibly TACo) for the object
# @param $result	the object to map
# @param $isa		the class hierarchy of the object
# @param $methods	the method name map for the object
#
# @return		<a href='./Apartment/Client.html'>TAC</a> for the object
#*/
sub add_mapped_object {
	my ($objid, $tac, $result, $isa, $methods) = @_;
	$objmap{$result} = $tac;
	$objidmap[$objid] = [ $result, $isa, $methods ];
	$objrefcnts[$objid] = 1;
	return $tac;
}

#/**
# Allocate a unique object ID. ID's are indexes into the
# object ID map array; a scan of the array is performed
# to locate the first free entry. If no free entries remain,
# the array is extended.
#
# @static
#
# @return		the object ID
#*/
sub alloc_mapped_object {
	my $objid = 2;
	$objid++
		while ($objid < scalar @objidmap) && $objidmap[$objid];
	return $objid;
}

#/**
# Get current re-entrancy setting.
#
# @static
#
# @return		re-entrancy flag value
#*/
sub get_reentrancy {
	return $is_reentrant;
}

#/**
# Set re-entrancy flag.
#
# @static
# @param $reentrancy the boolean value for the flag
#
# @return		previous re-entrancy flag value
#*/
sub set_reentrancy {
	my $old = $is_reentrant;
	$is_reentrant = $_[0];
	return $old
}

#/**
# Get current autoload setting.
#
# @static
#
# @return		autoload flag value
#*/
sub get_autoload {
	return $autoload_all;
}

#/**
# Set autoload flag.
#
# @static
# @param $autoload the boolean value for the flag
#
# @return		previous $autoload_all flag value
#*/
sub set_autoload {
	my $old = $autoload_all;
	$autoload_all = $_[0];
	return $old
}

#/**
# Get current closure call behaviors
#
# @static
#
# @return		closure call behaviors bitmask
#*/
sub get_closure_behavior {
	return $closure_calls || 0;
}

#/**
# Set closure call behaviors
#
# @static
# @param $behavior the bitmask of TA_SIMPLEX and/or TA_URGENT values
#
# @return		previous $closure_calls bitmask value
#*/
sub set_closure_behavior {
	my $old = $closure_calls || 0;
	$closure_calls = $_[0];
	return $old
}
###########################################################
#
#	ASYNC METHOD CALL METHODS
#
###########################################################
#/**
# Starts an asynchronous method or closure call.
# Sets the <i>thread-local</i> TAC async flag class variable.
# When the next proxied TAC method/closure call
# is invoked within the thread, the TAC will
# <ol>
# <li>add itself and the pending method/closure request identifier,
# to T::A's <i>thread-local</i> async TAC map class variable
# <li>clear the TAC async flag
# <li>return the TAC for the method/closure request.
# </ol>
# <p>
# For async method calls, the parameter is the TAC object; for proxied
# closure calls, the closure is specified. The returned value is the provided
# TAC or closure, in order to support the following syntax<br>
# <pre>
# my $tac = Thread::Apartment::start($tac)->someMethod(@params);
# my $tac = Thread::Apartment::start($closure)->(@params);
# </pre>
#
# @static
# @param $tac_or_closure	TAC or closure to be invoked asynchronously
#
# @return		the input TAC or closure parameter
#*/
sub start {
	Thread::Apartment::Client::set_async($_[0]);
	return $_[0];
}

#/**
# Map a TAC to a async method/closure request ID.
# Called by a TAC when the async request has been initiated.
#
# @static
# @param $key	TAC or closure being mapped
# @param $tac	TAC to map to async request id
# @param $id	request id
#
# @return		The TAC object.
#*/
sub map_async_request_id {
# if called as a class method
	shift unless
		(ref $_[0] && (! $_[0]->isa('Thread::Apartment')));
	my $key = shift;
	$tacmap{$key} = [ @_ ];
	return $key;
}

#/**
# Wait for completion of pending method/closure requests
# on <b>all</b> of the specified TACs/closures. If no TACs/closures are
# specified, waits for all TACs/closures currently in the async TAC map.
# Returns when the pending requests are completed, using the
# Thread::Queue::Duplex <code>wait_all()</code> class method.
# <p>
# Note that the application is responsible for calling
# <a href='classdocs/Thread/Apartment/Client.html#get_pending_results'>
# get_pending_results()</a> on the appropriate TACs to get any method/closure
# return values.
# <p>
# For closures, the input parameter is the closure
#
# @static
# @param @tac_list	(optional) list of TACs or closures to wait for;
#					default is all pending TACs
#
# @return		list of TACs that have rendezvoused; note that closures
#				will be replaced by an appropriate TAC
#*/
sub rendezvous {
# if called as a class method
	shift unless
		(ref $_[0] && ((ref $_[0] eq 'CODE') || (! $_[0]->isa('Thread::Apartment'))));

	my @pending = ();
	if (scalar @_) {
		foreach (@_) {
			push(@pending, $tacmap{$_})
				if exists $tacmap{$_};
		}
	}
	else {
		@pending = values %tacmap;
	}
#	print STDERR "Pending is ", scalar @pending, "\n";
	return (scalar @pending) ?
		Thread::Queue::Duplex->wait_all(@pending) : ();
}

#/**
# Wait for completion of pending method/closure requests
# on <b>any</b> of the specified TACs. If no TACs are
# specified, waits for any TACs currently in the async TAC map.
# Returns when the pending requests are completed, using the
# Thread::Queue::Duplex <code>wait_any()</code> class method.
# <p>
# Note that the application is responsible for calling
# <a href='classdocs/Thread/Apartment/Client.html#get_pending_results'>
# get_pending_results()</a> on the appropriate TACs to get any method/closure
# return values.
# <p>
# For closures, the input TAC parameter is the TAC returned by <A href='#start'>start()</a>.
#
# @static
# @param @tac_list	(optional) list of TACs to wait for;
#					default is all pending TACs
#
# @return		list of TACs that have rendezvoused
#*/
sub rendezvous_any {
# if called as a class method
	shift unless
		(ref $_[0] && ((ref $_[0] eq 'CODE') || (! $_[0]->isa('Thread::Apartment'))));
	my @pending = ();
	if (scalar @_) {
		foreach (@_) {
			push(@pending, $tacmap{$_})
				if exists $tacmap{$_};
		}
	}
	else {
		@pending = values %tacmap;
	}
	return (scalar @pending) ?
		Thread::Queue::Duplex->wait_any(@pending) : ();
}

#/**
# Wait upto to $timeout seconds for completion of pending
# method/closure requests on <b>all</b> of the specified TACs.
# If no TACs are specified, waits for any TACs currently in the async TAC map.
# Returns when the pending requests are completed, or the timeout has expired,
# using the Thread::Queue::Duplex <code>wait_all_until()</code> class method.
# <p>
# Note that the application is responsible for calling
# <a href='classdocs/Thread/Apartment/Client.html#get_pending_results'>
# get_pending_results()</a> on the appropriate TACs to get any method/closure
# return values.
# <p>
# For closures, the input TAC parameter is the TAC returned by <A href='#start'>start()</a>.
#
# @static
# @param $timeout	timeout in seconds to wait for completion
# @param @tac_list	(optional) list of TACs to wait for;
#					default is all pending TACs
#
# @return		undef if $timeout expired; otherwise, the list of TACs that have rendezvoused
#*/
sub rendezvous_until {
# if called as a class method
	shift if (ref $_[0] || ($_[0] eq 'Thread::Apartment'));
	my $timeout = shift;

	my @pending = ();
	if (scalar @_) {
		foreach (@_) {
			push(@pending, $tacmap{$_})
				if exists $tacmap{$_};
		}
	}
	else {
		@pending = values %tacmap;
	}
	return (scalar @pending) ?
		Thread::Queue::Duplex->wait_all_until($timeout, @pending) : ();
}

#/**
# Wait upto to $timeout seconds for completion of pending
# method/closure requests on <b>any</b> of the specified TACs.
# If no TACs are specified, waits for any TACs currently in the async TAC map.
# Returns when the pending requests are completed, or the timeout has expired,
# using the Thread::Queue::Duplex <code>wait_all_until()</code> class method.
# <p>
# Note that the application is responsible for calling
# <a href='classdocs/Thread/Apartment/Client.html#get_pending_results'>
# get_pending_results()</a> on the appropriate TACs to get any method/closure
# return values.
# <p>
# For closures, the input TAC parameter is the TAC returned by <A href='#start'>start()</a>.
#
# @static
# @param $timeout	timeout in seconds to wait for completion
# @param @tac_list	(optional) list of TACs to wait for;
#					default is all pending TACs
#
# @return		undef if $timeout expired; otherwise, the list of TACs that
#				have rendezvoused
#*/
sub rendezvous_any_until {
# if called as a class method
	shift if (ref $_[0] || ($_[0] eq 'Thread::Apartment'));
	my $timeout = shift;

	my @pending = ();
	if (scalar @_) {
		foreach (@_) {
			push(@pending, $tacmap{$_})
				if exists $tacmap{$_};
		}
	}
	else {
		@pending = values %tacmap;
	}
	return (scalar @pending) ?
		Thread::Queue::Duplex->wait_any_until($timeout, @pending) : ();
}

#/**
# Return the pending request ID for the input TAC.
# Called from TAC::<a href='./Apartment/Client.html#get_pending_results'>get_pending_results()</a>
# to recover the pending request ID. Causes the TAC and request ID to be removed
# from the TAC map.
#
# @static
# @param $tac	TAC for which the pending request ID is to be returned
#
# @return		undef if the input TAC has no pending requests;
#				otherwise, the request id
#*/
sub get_pending_request {
# if called as a class method
	shift unless
		(ref $_[0] && ((ref $_[0] eq 'CODE') || (! $_[0]->isa('Thread::Apartment'))));
	if (exists $tacmap{$_[0]}) {
		my $t = delete $tacmap{$_[0]};
		return $t->[1];
	}
#
#	must be a closure, go look for its TAC
#
	my ($tac, $id);
	while (($tac, $id) = each %tacmap) {
		delete $tacmap{$tac},
		return $id->[1]
			if ($id->[0] eq $_[0]);
	}
	return undef;
}

sub set_ta_debug {
	$ta_debug = 1;
}

1;

__END__
