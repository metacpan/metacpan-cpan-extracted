#/**
# Abstract base class for Event driven objects.
# Extends <a href='./Server.html'>Thread::Apartment::Server</a>
# to provide a poll() method for event-driven (e.g., I/O) server
# objects to permit interleaving of event handling and TQD polling
# (e.g., objects which must detect I/O completions)
# <p>
# Licensed under the Academic Free License version 2.1, as specified in the
# License.txt file included in this software package, or at
# <a href="http://www.opensource.org/licenses/afl-2.1.php">OpenSource.org</a>.
#
# @author D. Arnold
# @since 2005-12-01
# @self	$self
#*/
package Thread::Apartment::EventServer;

use Thread::Apartment::Server;
use base qw(Thread::Apartment::Server);

our $VERSION = '0.50';

#/**
# Poll events.
#*/
sub poll {
	my $self = shift;
	return $self;
}

1;
