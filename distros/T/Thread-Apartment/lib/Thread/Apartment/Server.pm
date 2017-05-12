#/**
# Abstract base class for proxied objects. Also
# acts as a container class for POPO's. Provides
# introspection methods to collect an object's
# class hierarchy, public methods and method
# behavior map, as well as marshalling results
# of method calls, and creating wrappers for
# proxied closures.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
#*/
package Thread::Apartment::Server;

use Carp;
use Exporter;
use Class::ISA;
use Class::Inspector;
use Thread::Apartment;
use Thread::Apartment::Common;
use Thread::Apartment::Client;
use Thread::Apartment::Container;

use Thread::Apartment::Common qw(:ta_method_flags);

use base qw(Exporter Thread::Apartment::Common);
#
#	implementing class should override these
#
use strict;
use warnings;

our @EXPORT = qw( );
our @EXPORT_OK = qw(
	$tqd
	$timeout
	$installed);

our $VERSION = '0.50';

our %no_marshal = qw(
	ARRAY 1
	HASH 1
	SCALAR 1
	CODE 1
);
#
#	thread-global objects set by T::A on create/CLONE
#
our $tqd;
our $timeout;
our $installed;

#sub CLONE {
#	$tqd = undef;
#	$timeout = undef;
#	$installed = undef;
#}

#/**
# Constructor. Used for objects using list-based constructor
# parameter lists.
#
# @param $tac	TAC for the object
#
# @return		Thread::Apartment::Server object
#*/
sub new_from_list {
	my $class = shift;
	my $tac = shift;

	my $self = {};
	bless $self, $class;
	$self->set_client($tac);
	return $self;
}
#/**
# Constructor. Used for objects using hash-based constructor
# parameter lists.
#
# @param $tac	TAC for the object
#
# @return		Thread::Apartment::Server object
#*/
sub new_from_hash {
	my ($class, %args) = @_;

	my $self = {};
	bless $self, $class;
	$self->set_client($args{AptTAC});
	return $self;
}
#/**
# Introspects a class or object. Used to
# <ol>
# <li>collect the class/object's class hierarchy for proxied isa() calls
# <li>collect a map of public method names to their behavior flags for
#	proxied can() and method calls
# <li>establish the object as reentrant, and/or AUTOLOAD-all
# <li>create a TAC for the object
# <li>create a TACo for installed objects
# </ol>
#
# @static
# @param $base		either a class name, or an object instance
# @param $objid		unique object ID assigned to the object
# @param $autoload	(optional) boolean indicating the object is autoload-all; default false
#
# @returnlist	(arrayref if class hierarchy, hashref of public method map, object's TAC)
#*/
sub introspect {
	my ($base, $objid, $autoload) = @_;

	$base = ref $base if ref $base;
	my @isa = Class::ISA::self_and_super_path($base);
	my %method_hash = ();
	my ($simplex, $urgent, $no_objects) =
		${base}->isa('Thread::Apartment::Server') ?
			(${base}->get_simplex_methods(), ${base}->get_urgent_methods(),
				${base}->get_no_objects()) :
			({}, {}, {});
#
#	get simple methods names first
#
	my $methods = Class::Inspector->methods($base, 'public');
#
#	include AUTOLOAD if autoload-all
# 	we retain explicit method names to permit simplex/urgent
#	flagging; note that the class may also set AUTOLOAD as simplex/urgent
#
	$method_hash{AUTOLOAD} = 0
		if $autoload || Thread::Apartment::get_autoload();
	my $mask;
	map {
		$method_hash{$_} =
			($simplex->{$_} ? TA_SIMPLEX : 0) |
			($urgent->{$_} ? TA_URGENT : 0) |
			($no_objects->{$_} ? TA_NO_OBJECTS : 0);
	} @$methods;
#
#	then get fully qualified ones (ignoring our local methods)
#	(might be nice to try and get simplex info from these, but
#	we'll punt for now)
#
	foreach my $class (@isa) {
		next if ($class eq $base);
		$methods = Class::Inspector->methods($class, 'public');
		$method_hash{$class . '::' . $_} = 0
			foreach (@$methods);
	}
#
#	and create a TAC for us
#
	my $tac = ${base}->isa('Thread::Apartment::Server') ?
		${base}->create_client($tqd, $objid, \@isa, \%method_hash, $timeout) :
		Thread::Apartment::Server::create_client($base, $tqd, $objid, \@isa, \%method_hash, $timeout);
#
#	convert TAC to TACo if we're being installed, not created
#
	$tac = Thread::Apartment::Container->new(1, $tac)
		if $installed;

	return (\@isa, \%method_hash, $tac);
}
#/**
# Creates a TAC for the object or class;
# a subclass may override this to provide their
# own TAC implementation
#
# @static
#
# @return		Thread::Apartment::Client object
#*/
sub create_client {
	my $class = shift;
	$class = ref $class if ref $class;
#
#	rest of params are
#		$tqd, $id, $isa, $methods, $timeout
#	we add our tid to the end
#
	return Thread::Apartment::Client->new($class, @_, threads->self()->tid());
}
#/**
# Set the local reference to an object's TAC, so it can be passed
# to other T::A objects. Note that this is usually called
# from the constructor of TAS implementors.
#
# @param $tac	Thread::Apartment::Client for the object
#
# @return		Thread::Apartment::Server object
#*/
sub set_client {
	my ($self, $tac) = @_;
	$self->{_tas_tac} = $tac;
	return $self;
}

#/**
# Return the object's TAC.
#
# @return		Thread::Apartment::Client for the object
#*/
sub get_client {
	return shift->{_tas_tac};
}

#/**
# Virtual function to return a hashref of public method names
# that are simplex.
# (i.e., do not return results, and hence the TAC does not
# wait for returned results when another T::A object
# calls the method). Called during introspection.
#
# @static
# @return		hashref of public simplex methods
#*/
sub get_simplex_methods {
	return {};
}

#/**
# Virtual function to return a hashref of public method names
# that are urgent.
# (i.e., proxied method calls should be placed at the head of
# the TQD in order to be serviced ASAP).
# Called during introspection.
#
# @static
# @return		hashref of public urgent methods
#*/
sub get_urgent_methods {
	return {};
}

#/**
# Virtual function to return a hashref of public method names
# that are do not return objects.
# Called during introspection. The returned map is used
# internally to optimize marshalling of method call results.
#
# @static
# @return		hashref of public non-object-returning methods
#*/
sub get_no_objects {
	return {};
}
#/**
# Pure virtual function called when an object is installed in
# a thread.
#
# @static
#*/
sub install {
}
#/**
# Pure virtual function called when an object is evicted from
# a thread. Useful for cleaning up any persistent context.
#
#*/
sub evict {
}

#/**
# Set debug level.
#
# @param $level	debug level
#
#*/
sub debug {
	$_[0]->{_debug} = $_[1];
}

#/**
# Marshalls results from method calls. Overrides
# <a href='./Common.html#marshal'>Thread::Apartment::Common::marshal</a>
# to trap returned objects for conversion to TACs by adding to, or recovering
# from, the containing apartment thread's object map.
#
# @static
# @param @results	list of results to be marshalled
#
# @return		threads::shared arrayref of marshalled parameters
#*/
sub marshalResults {
	my $self = shift;

	scan_for_objects(@_);
	return $self->marshal(@_);
}

sub scan_for_objects {
	foreach (0..$#_) {
#
#	leave non-objects, or TQQs as is for final marshal
#
		my $result = $_[$_];
		my $type = ref $result;
		next if (!$type) ||
			$no_marshal{$type} ||
			$result->isa('Thread::Queue::Queueable');
#
#	scan for previous instance; if found, replace
#	with its TAC
#
		$_[$_] = Thread::Apartment::get_tac_for_object($result);
		next
			if $_[$_];
#
#	locate free spot in map
#
		my $objid = Thread::Apartment::alloc_mapped_object();
#
#	introspect it
#	save it in the map
#	create a TAC for it
#	NOTE: if its a TAS, we may end up w/ duplicate TACs here,
#	but we need to coerce it into our hierarchy
#
		my ($isa, $methods, $tac) = $result->isa('Thread::Apartment::Server') ?
			$result->introspect($objid) : introspect($result, $objid);

		$result->set_client($tac)
			if $result->isa('Thread::Apartment::Server');
#
#	if we're running in an installed thread, then create a TACo
#
		$tac = Thread::Apartment::Container->new($objid, $tac)
			if $installed && (! $tac->isa('Thread::Apartment::Container'));

		$_[$_] =
			Thread::Apartment::add_mapped_object($objid, $tac, $result, $isa, $methods);
	}
}

#/**
# Create a <a href='./Closure.html'>Thread::Apartment::Closure</a>
# object to contain a duplex, non-urgent closure, and map it into
# the apartment thread's closure map.
#
# @static
# @param $closure	closure to be contained.
#
# @return		Thread::Apartment::Closure object
#*/
sub new_tacl {
	my ($self, $closure) = @_;
	return Thread::Apartment::register_closure($closure, 0);
}

#/**
# Create a <a href='./Closure.html'>Thread::Apartment::Closure</a>
# object to contain a simplex, non-urgent closure, and map it into
# the apartment thread's closure map.
#
# @static
# @param $closure	closure to be contained.
#
# @return		Thread::Apartment::Closure object
#*/
sub new_simplex_tacl {
	my ($self, $closure) = @_;
	return Thread::Apartment::register_closure($closure, TA_SIMPLEX);
}

#/**
# Create a <a href='./Closure.html'>Thread::Apartment::Closure</a>
# object to contain a duplex, urgent closure, and map it into
# the apartment thread's closure map.
#
# @static
# @param $closure	closure to be contained.
#
# @return		Thread::Apartment::Closure object
#*/
sub new_urgent_tacl {
	my ($self, $closure) = @_;
	return Thread::Apartment::register_closure($closure, TA_URGENT);
}

#/**
# Create a <a href='./Closure.html'>Thread::Apartment::Closure</a>
# object to contain a simplex, urgent closure, and map it into
# the apartment thread's closure map.
#
# @static
# @param $closure	closure to be contained.
#
# @return		Thread::Apartment::Closure object
#*/
sub new_urgent_simplex_tacl {
	my ($self, $closure) = @_;
	return Thread::Apartment::register_closure($closure, TA_SIMPLEX | TA_URGENT);
}
#/**
# Init class/thread-global variables
#
# @static
# @param $tqd		apartment's TQD
# @param $timeout	response timeout for TQD
# @param $installed	flag to indicate if the object has been install()'ed, rather
#					than constructed
#
#*/
sub init_tas {
	($tqd, $timeout, $installed) = @_;
}

1;
