#/**
# Abstract base class defining the interfaces, and providing
# simple marshalling methods, for complex object to be passed
# across a <a href='./Duplex.html'>Thread::Queue::Duplex</a>
# queue.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$obj
#*/
package Thread::Queue::Queueable;
#
#	abstract class to permit an object to be
#	marshalled in some way before pushing onto
#	a Thread::Queue::Duplex queue
#
require 5.008;

use threads;
use threads::shared;

use strict;
use warnings;

our $VERSION = '0.90';

#/**
# Marshal an object for queueing to a <A href='./Duplex.html'>Thread::Queue::Duplex</a>
# queue. Called by any of TQD's <A href='./Duplex.html#enqueue'>enqueue()</a> methods,
# as well as <A href='./Duplex.html#respond'>respond()</a> method.
# <p>
# The default implementation <A href='#curse>curse()'s</a> the input
# object into either a shared array or shared hash (depending on the base structure
# of the object), and returns a list consisting of the object's class name, and the cursed object.
#
# @returnlist	list of (object's class, object's marshalled representation)
#*/
sub onEnqueue {
	my $obj = shift;
#
#	capture class name, and create cursed
#	version of object
#
	return (ref $obj, $obj->curse());
}

#/**
# Unmarshall an object after being dequeued. Called by any of TQD's
# <a href='./Duplex.html#dequeue'>dequeue()</a> methods,
# as well as the various request side dequeueing
# methods (e.g., <a href='./Duplex.html#wait'>wait()</a>).
# <p>
# The default implementation <a href='#redeem'>redeem()'s</a> the input object
# to copy the input shared arrayref or hashref into a nonshared equivalent, then
# blessing it into the specified class, returning the redeemed object.
#
# @param $object the marshalled representation of the object
# @return		the unmarshalled <i>aka</i> "redeemed" object
#*/
sub onDequeue {
	my ($class, $obj) = @_;
#
#	reconstruct as non-shared by redeeming
#
	return $class->redeem($obj);
}

#/**
# Pure virtual function to apply any object-specific cancel processing. Called by TQD's
# <a href='./Duplex.html#cancel>cancel()</a> methods,
# as well as the <a href='./Duplex.html#respond>respond()</a> method
# when a cancelled operation is detected.
#
# @return		1
#*/
sub onCancel {
	my $obj = shift;
	return 1;
}
#/**
# Marshal an object into a value that can be passed via
# a <a href='./Duplex.html'>Thread::Queue::Duplex</a> object.
# <p>
# Called by TQD's various <a href='./Duplex.html#enqueue'>enqueue()</a> and
# <a href='./Duplex.html#respond'>respond()</a> methods
# when the TQQ object is being enqueue'd. Should return an unblessed,
# shared version of the input object.
# <p>
# Default returns a shared
# arrayref or hashref, depending on the object's base structure, with
# copies of all scalar members.
# <p>
# <b>Note</b> that objects with more complex members will need to
# implement an object specific <code>curse()</code> to do any deepcopying,
# including curse()ing any subordinate objects.
#
# @return		marshalled version of the object
#*/
sub curse {
	my $obj = shift;
#
#	if we're already shared, don't share again
#
	return $obj if threads::shared::_id($obj);

	if ($obj->isa('HASH')) {
		my %cursed : shared = ();
		$cursed{$_} = $obj->{$_}
			foreach (keys %$obj);
		return \%cursed;
	}

	my @cursed : shared = ();
	$cursed[$_] = $obj->[$_]
		foreach (0..$#$obj);
	return \@cursed;
}
#/**
# Unmarshall an object back into its blessed form.
# <p>
# Called by TQD's various <a href='./Duplex.html#dequeue'>dequeue()</a> and
# <a href='./Duplex.html#wait'>wait</a> methods to
# "redeem" (i.e., rebless) the object into its original class.
# <p>
# Default creates non-shared copy of the input object structure,
# copying its scalar contents, and blessing it into the specified class.
# <p>
# <b>Note</b> that objects with complex members need to implement
# an object specific <code>redeem()</code>, possibly recursively
# redeem()ing subordinate objects <i>(be careful
# of circular references!)</i>
#
# @param $object	marshalled <i>aka</i> "cursed" version of the object
#
# @return		unmarshalled, blessed version of the object
#*/
sub redeem {
	my ($class, $obj) = @_;
#
#	if object is already shared, just rebless it
#	NOTE: we can only do this when threads::shared::_id() is defined
#
	return bless $obj, $class
		if threads::shared->can('_id') && threads::shared::_id($obj);
#
#	we *could* just return the blessed object,
#	which would be shared...but that might
#	not be the expected behavior...
#
	if (ref $obj eq 'HASH') {
		my $redeemed = {};
		$redeemed->{$_} = $obj->{$_}
			foreach (keys %$obj);
		return bless $redeemed, $class;
	}

	my $redeemed = [];
	$redeemed->[$_] = $obj->[$_]
		foreach (0..$#$obj);
	return bless $redeemed, $class;
}

1;