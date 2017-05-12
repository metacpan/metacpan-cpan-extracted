#/**
# Provides a proxy to permit closures to be passed
# between, and invoked by, external apartment threads.
# <p>
# Implements <a href='http://search.cpan.org/perldoc?Thread::Queue::Queueable'>Thread::Queue::Queueable</a>
# to permit curse/redeem operations when passed between threads via TQDs.
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self $self
#*/
package Thread::Apartment::Closure;
#
#	simple container class for closures
#

use Thread::Queue::Queueable;

use base qw(Thread::Queue::Queueable);

use strict;
use warnings;

our $VERSION = '0.50';

#/**
# Constructor. Stores the arguments into a blessed arrayref.
#
# @param $sig	unique apartment thread signature used to reject calls to
#				stale closures after an apartment thread has been recycled
# @param $id	unique closure ID used to lookup the closure in the originating
#				apartment thread's closure map
# @param $tac	Thread::Apartment::Client object for the originating apartment thread
#
# @return		Thread::Apartment::Closure object
#*/
sub new {
	my ($class, $sig, $id, $tac) = @_;
	return bless [$sig, $id, $tac], $class;
}
#/**
# Redeem the object after being passed to a thread.
# Causes the TACl contents to be converted to a closure
# that invokes a well known method on the originating thread.
#
# @param $class	class to redeem to (unused)
# @param $obj	the object structure being redeemed
#
# @return		closure to invoke proxied closure on the TACl's TAC
#*/
sub redeem {
	my ($class, $obj) = @_;
#
#	returns a closure
#
	my ($sig, $id, $tac) = @$obj;
	return sub {
		scalar (@_) ?
			$tac->ta_invoke_closure($sig, $id, @_) :
			$tac->ta_invoke_closure($sig, $id);
		};
}
1;
