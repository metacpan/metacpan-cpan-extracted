#/**
# Abstract base class for Multiplexing server objects.
# Extends <a href='./Server.html'>Thread::Apartment::Server</a>
# to provide a multiplexing server which explicitly polls its
# TQD for incoming method calls (i.e., inverts the control scheme
# of T::A::Server). (Useful for object which implement their
# own control loop, e.g., Perl/Tk).
# <p>
# Uses <a href='./Server.html'>T::A::Server's</a> constructor.
# <p>
# <a href='../Apartment.html#run'>T::A::run</a> calls the object's run() method,
# which is responsible for testing the TQD at regular intervals
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
#*/
package Thread::Apartment::MuxServer;

use Thread::Apartment;
use Thread::Apartment::Server;
use Thread::Apartment::Server qw($tqd $timeout $installed);
use Thread::Apartment::Common qw(:ta_method_flags);

use base qw(Thread::Apartment::Server);

use strict;
use warnings;

our $VERSION = '0.50';

#/**
# Thread governor for MuxServer subclasses.
# Pure virtual function to be implemented by concrete MuxServer
# classes. Interleaves method request handling with its own
# class-specific control loop.
# <p>
# Returns when either the class has determined it is completed,
# or when a STOP command is received.
#
# @return 1 if the object is voluntarily vacating the thread;
#		undef if the thread has been STOP'ed.
#
#*/
sub run {
	my $self = shift;
}

#/**
# Polls the TQD and handles any received method/closure
# requests. Mimics the behavior of Thread::Apartment's
# internal thread governor.
#
# @return		1
#*/
sub handle_method_requests {
	my $self = shift;

	my $tid = threads->self()->tid();
	print STDERR "Mux Polling TQD\n"
		if $self->{_debug};
#
#	copied from T::A::_run, but different enough that we
#	can't refactor to a common method
#
	my ($req, $id, $method, $objid, $wantary, $obj) =
		(undef, undef, undef, undef, undef, undef);
	my ($simplex, $async, $sig, $cid, $closure) = (undef, undef, undef, undef, undef);
	my $methods = undef;
#
#	create closure for responses; we'll switch between this
#	and any async respons closure
#
	my $tqdresp = sub { $tqd->respond(@_); };
	my $respmeth = undef;
	my @resp = ();
	my $resp = undef;

	while ($req = $tqd->dequeue_nb()) {

#print STDERR ref $self, " got request in thread $tid\n";

#		print STDERR "Stopping...\n" and
		return undef
			if ($req->[1] eq 'STOP');
#
#	must be function call
#
		($id, $method) = (shift @$req, shift @$req);

#print STDERR "MuxServer: $method\n";

		($objid, $wantary) = ($method eq 'ta_install') ?
			(undef, undef) : (shift @$req, shift @$req);
#
#	if unknown object id, post error
#
print STDERR "Unknown object for method $method\n"
	unless $objid;
		$obj = Thread::Apartment::get_object_by_id($objid);
		$tqd->respond($id, undef, "Unknown object (ID $objid)."),
		next
			unless $obj;
#
#	check for ref count (this is simplex)
#
		Thread::Apartment::add_object_reference($objid),
		next
			if ($method eq '_add_ref');

		if ($method eq 'DESTROY') {
#
#	only destroy when refcount <= 0
#	also a simplex method
#
			return undef
				unless Thread::Apartment::destroy_object($objid);
			next;
		}
#
#	permits the object to be forced out, wo/ regard to objrefcnts
#
		$self->evict(),
		return Thread::Apartment::evict_objects()
			if ($method eq 'evict');
#
#	verify method
#
		$respmeth = $tqdresp;
		$methods = Thread::Apartment::get_object_methods($objid);
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
#print STDERR "MuxServer real method is $method\n"
#	if $async;
#
#	unmarshal args
#
		$req = scalar @$req ? $self->unmarshal($req->[0]) : [];

		if ($async) {
#
#	async method call
#
#print STDERR "MuxServer:: handling async\n";

			$respmeth = $req->[0];
			$tqd->respond($id, undef, "No closure provided for async call to $method."),
			next
				unless $respmeth && (ref $respmeth) && (ref $respmeth eq 'CODE');

			$respmeth->($id, undef, "Unknown method $method."),
			next
				unless (exists $methods->{$method}) ||
					(exists $methods->{AUTOLOAD});
		}

		$simplex = (exists $methods->{$method}) ?
			($methods->{$method} & TA_SIMPLEX) : 0;

		if ($method eq 'ta_invoke_closure') {
#
#	closure call
#	verify the signature and the ID
#	then call the closure
#
#print STDERR "MuxServer:: handling closure\n";

			($sig, $cid) = (shift @$req, shift @$req);

			print STDERR "T::A::Mux::handle_method_requests: calling closure $cid\n"
				if $self->{_debug};

			$closure = Thread::Apartment::get_closure($sig, $cid);
			$respmeth->($id, undef, "Stale closure call to thread $tid."),
			next
				unless $closure;

			$simplex = $cid & TA_SIMPLEX;

			if ($wantary) {
				@resp = $closure->(@$req);
			}
			elsif (defined($wantary)) {
				$resp[0] = $closure->(@$req);
			}
			else {
				$closure->(@$req);
				$resp[0] = 1;
			}

			print STDERR "T::A::Mux::handle_method_requests: returned from $method on object $objid\n"
				if $self->{_debug};
		}
		else {
			print STDERR "T::A::Mux::handle_method_requests: calling $method on object $objid\n"
				if $self->{_debug};

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

			print STDERR "T::A::Mux::handle_method_requests: returned from $method on object $objid\n"
				if $self->{_debug};
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
		$resp = $self->marshalResults(@resp);

		$async ? $respmeth->(@resp) : $respmeth->($id, $resp);

		print STDERR ($async ?
			"T::A::Mux::handle_method_requests: async response for $method on object $objid\n" :
			"T::A::Mux::handle_method_requests: responding for $method on object $objid\n")
			if $self->{_debug};
	}
	return 1;
}

1;
