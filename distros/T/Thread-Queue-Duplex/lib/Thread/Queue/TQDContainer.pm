#/**
# Abstract class for Thread::Queue::Duplex container object.
# Used by TQD's wait() class methods, to simplify waiting
# for an object with a pending queue event (e.g.,
# Thread::Apartment::Client objects).
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$obj
# @see		<a href='./Queueable.html'>Thread::Queue::Queueable</a>
#*/
package Thread::Queue::TQDContainer;
#
#	Copyright (C) 2005,2006, Presicient Corp., USA
#
#/**
# Returns the contained TQD object.
# Abstract method that assumes the object is hash based, and
# the contained TQD is in a member named <b>_tqd</b>.
#
# @return		the contained TQD object
#*/
sub get_queue { return $_[0]->{_tqd}; }

#/**
# Set the contained TQD object.
# Abstract method that assumes the object is hash based, and
# the contained TQD is in a member named <b>_tqd</b>.
#
# @param $tqd	the TQD to be contained
#
# @return		the TQDContainer object
#*/
sub set_queue { $_[0]->{_tqd} = $_[1]; return $_[0]; }

1;