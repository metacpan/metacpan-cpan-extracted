#/**
# Provides a non-threads::shared container proxy class for
# installed objects.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
#*/
package Thread::Apartment::Container;

use Thread::Apartment qw(get_object_by_id);
use Thread::Queue::Queueable;
use Thread::Apartment::Server;
use Thread::Apartment::Common qw(:ta_method_flags);

use base qw(Thread::Queue::Queueable);

our $AUTOLOAD;

use strict;
use warnings;

our $VERSION = '0.50';

#/**
# Constructor. Creates a container for an object's ID and TAC.
#
# @param $id	ID of proxied object
# @param $tac	TAC of proxied object
#
# @return		Thread::Apartment::Container object
#*/
sub new {
	my ($class, $id, $tac) = @_;

	return bless {
		_tac    => $tac, 			# TAC for contained class
		_id 	=> $id,				# object unique ID (for object hierarchies)
	}, $class;
}
#/**
# Overload UNIVERSAL::isa() to test the class hierarchy of the proxied object.
#
# @param $class		class to check if implemented by the proxied object
#
# @return		1 if the proxied object implements $class; undef otherwise
#*/
sub isa {
	return (($_[1] eq 'Thread::Queue::Queueable') ||
		($_[1] eq 'Thread::Apartment::Client') ||
		($_[1] eq 'Thread::Apartment::Container')) ? 1 :
		(Thread::Apartment::get_object_by_id($_[0]->{_id}) &&
			Thread::Apartment::get_object_by_id($_[0]->{_id})->isa($_[1]))
}

#/**
# Overload UNIVERSAL::can() to test the available methods of the proxied object.
#
# @param $method	method to check if implemented by the proxied object
#
# @return		if the proxied object exports $method (or exports AUTOLOAD),
#				the can() result of the proxied object.
#*/
sub can {
	return (Thread::Apartment::get_object_by_id($_[0]->{_id}) &&
		Thread::Apartment::get_object_by_id($_[0]->{_id})->can($_[1]));
}
#/**
# Set debug level. When set to a "true" value, causes the TAC to emit
# diagnostic information.
#
# @param $level	debug level. zero or undef turns off debugging; all other values enable debugging
#
# @return		the new level
#*/
sub debug { $_[0]->{_tac_debug} = $_[1]; }

sub AUTOLOAD {
#
#	called in client stub
#	passes method name
#
	my $self = shift;
	my $contained = Thread::Apartment::get_object_by_id($self->{_id});

	unless ($contained) {
		$@ = "Can't locate contained object.";
		print STDERR $@, "\n"
			if $self->{_tac_debug};
		return undef;
	}

	my $method = $AUTOLOAD;

	print STDERR "TACO::AUTOLOAD: Method is $method\n"
		if $self->{_tac_debug};

	return if ($method=~/::DESTROY$/);
#
#	get rid of leading stuff
#
#warn "requested method $method\n";

	$method=~s/^Thread::Apartment::Container:://;
	my $closure;

	$method = $1,
	$closure = shift
		if ($method=~/^ta_async_(.+)$/) &&
			$_[0] && (ref $_[0]) && (ref $_[0] eq 'CODE');

	unless ($contained->can($method) ||
		$contained->can('AUTOLOAD')) {
		$@ = "Can't locate object method \"$method\" via package \"" .
			$self->{_tac}->get_proxied_class() . '"';
		print STDERR $@, "\n"
			if $self->{_tac_debug};
		return undef;
	}
#
#	NOTE: we ignore simplex/urgent here, since we're running
#	in the same thread; we just call the method on the contained
#	object
#
	my @results = (1);	# assume void context
	if (wantarray) {
		@results = $contained->$method(@_);
	}
	elsif (defined(wantarray)) {
		$results[0] = $contained->$method(@_);
	}
	else {
		$contained->$method(@_);
	}
#
#	NOTE: we must convert all returned objects to TACO's
#
	Thread::Apartment::Server::scan_for_objects(@results);
#
#	if async, call the closure
#
	$closure->(@results)
		if $closure;

	return wantarray ? @results : defined(wantarray) ? $results[0] : 1;
}

#/**
# Return the TQD for the proxied object.
#
# @return		TQD object
#*/
sub get_queue {
	return $_[0]->{_tac}->get_queue();
}

#/**
# Return current TQD timeout
#
# @return		TQD timeout in seconds
#*/
sub get_timeout {
	return $_[0]->{_tac}->get_timeout();
}

#/**
# Set TQD timeout
#
# @param $timeout	max. number of seconds to wait for TQD responses.
#
# @return		previous timeout value
#*/
sub set_timeout {
	return shift->{_tac}->set_timeout(@_);
}
#/**
# Invoke thread governor for installed MuxServer objects.
# Note that this method will not return until the proxied
# object exits the apartment thread.
#
# @return		1
#*/
sub run {
	return Thread::Apartment::get_object_by_id(1)->isa('Thread::Apartment::MuxServer') ?
		Thread::Apartment::get_object_by_id(1)->run : undef;
}

#/**
# Wait for the proxied object's apartment thread to exit.
#
# @return		1
#*/
sub join {
	return Thread::Apartment::get_object_by_id(1)->join();
}

#/**
# Stop the proxied object's apartment thread.
# <p>
# Note that this is only useful after an object has been
# installed, but before its run() method has been called.
#*/
sub stop {
	return Thread::Apartment::get_object_by_id(1)->stop;
}
#/**
# Overrides TQQ onEnqueue() to curse() the contained TAC.
#
# @returnlist	(contained TAC class, contained TAC)
#*/
sub onEnqueue {
	return (ref $_[0]->{_tac}, $_[0]->curse());
}

#/**
# Overrides TQQ curse() to return the contained TAC.
#
# @return		contained TAC
#*/
sub curse {
	return $_[0]->{_tac};
}

1;
