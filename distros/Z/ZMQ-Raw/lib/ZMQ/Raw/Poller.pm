package ZMQ::Raw::Poller;
$ZMQ::Raw::Poller::VERSION = '0.35';
use strict;
use warnings;
use ZMQ::Raw;

sub CLONE_SKIP { 1 }

=head1 NAME

ZMQ::Raw::Poller - ZeroMQ Poller class

=head1 VERSION

version 0.35

=head1 DESCRIPTION

ZeroMQ Poller

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $poller = ZMQ::Raw::Poller->new();
	$poller->add ($socket1, ZMQ::Raw->ZMQ_POLLIN);
	$poller->add ($socket2, ZMQ::Raw->ZMQ_POLLIN);

	# wait for up to 1000ms for an event
	if ($poller->wait (1000))
	{
		my $events = $poller->events ($socket1);
		if ($events & ZMQ::Raw->ZMQ_POLLIN)
		{
			print "POLLIN event on socket1\n";
		}

		$events = $poller->events ($socket2);
		if ($events & ZMQ::Raw->ZMQ_POLLIN)
		{
			print "POLLIN event on socket2\n";
		}
	}

=head1 METHODS

=head2 new( )

Create a new poller.

=head2 add( $socket, $events )

Poll for C<$events> on C<$socket>. C<$events> is a bitmask of values including:

=over 4

=item * C<ZMQ::Raw-E<gt>ZMQ_POLLIN>

At least one message may be received from the socket without blocking.

=item * C<ZMQ::Raw-E<gt>ZMQ_POLLOUT>

At least one message may be sent to the socket without blocking.

=back

=head2 remove( $socket )

Remove C<$socket> from the list of sockets to poll for events.

=head2 events( $socket )

Retrieve the events for C<$socket>. If C<$socket> was not previously added to
the poller this method will return C<undef>.

=head2 wait ( $timeout )

Wait for up to C<$timeout> milliseconds for an event. Returns the number of
items that had events.

This method may return C<undef> if the system call was interrupt, after which
it may be reattempted.

=head2 size( )

Retrieve the number of sockets currently polled.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Poller
