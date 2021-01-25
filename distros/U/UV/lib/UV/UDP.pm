package UV::UDP;

our $VERSION = '1.903';

use strict;
use warnings;
use Carp ();
use Exporter qw(import);
use parent 'UV::Handle';

our @EXPORT_OK = (@UV::UDP::EXPORT_XS,);

sub open
{
    my $self = shift;
    my ($fh) = @_;
    return $self->_open($fh->fileno);
}

1;

__END__

=encoding utf8

=head1 NAME

UV::UDP - UDP socket handles in libuv

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Socket;

    # A new socket handle will be initialised against the default loop
    my $udp = UV::UDP->new;

    $udp->connect(pack_sockaddr_in(1234, inet_aton("127.0.0.1"));
    $udp->send("Hello, server!\n");

    # set up the data recv callback
    $udp->on(recv => sub {
        my ($self, $err, $buf) = @_;
        say "More data: $buf";
    });
    $udp->recv_start();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's UDP|http://docs.libuv.org/en/v1.x/udp.html> handle.

=head1 EVENTS

L<UV::UDP> makes the following extra events available.

=head2 recv

    $udp->on("recv", sub {
        my ($self, $status, $buf, $addr) = @_;
        say "Received more data: <$buf>";
    });

The L<recv|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_recv_cb> callback
fires whenever a datagram is received on the socket to be passed to the
application.

=head1 METHODS

L<UV::UDP> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 open

    $udp->open($fh);

The L<open|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_open> method
associates the UDP handle with an existing filehandle already opened by the
process.

=head2 bind

    $udp->bind($addr);

The L<bind|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_bind> method
associates the UDP socket with the given local address.

=head2 connect

    $udp->connect($addr);

The L<connect|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_connect> method
associates the UDP socket with the given remote address.

=head2 getpeername

    my $addr = $udp->getpeername;

The L<getpeername|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_getpeername>
method returns a packed sockaddr string containing the remote address with
which this UDP handle is associated.

=head2 getsockname

    my $addr = $udp->getsockname;

The L<getsockname|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_getsockname>
method returns a packed sockaddr string containing the local address with
which this UDP handle is associated.

=head2 recv_start

    $udp->recv_start;

The L<recv_start|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_recv_start>
method starts the receiving side of the UDP socket handle. The C<recv> event
callback will be invoked whenever there is new data to be given to the
application.

=head2 recv_stop

    $udp->recv_stop;

The L<recv_stop|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_recv_stop>
method stops the receiving side of the stream handle.

=head2 send

    $udp->send($s, sub {
        say "Data has now been sent";
    });

The L<send|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_send> method
sends another datagram to the peer. The callback argument will be invoked when
it has been flushed to the filehandle.

    $udp->send($s, $addr, sub { ... });

Optionally additionally a destination address can be provided, for use with
unconnected UDP sockets.

=head2 try_send

    $udp->try_send($s);
    $udp->try_send($s, $addr);

The L<try_send|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_try_send>
method behaves similarly to L</send> but will fail with C<UV_EAGAIN> if it
cannot send the data immediately, rather than enqueing for later.

=head2 set_broadcast

    $udp->set_broadcast($on);

The L<set_broadcast|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_broadcast>
method turns broadcast on or off.

=head2 set_ttl

    $udp->set_ttl($ttl);

The L<set_ttl|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_ttl> method
sets the time-to-live of transmitted packets.

=head2 set_multicast_loop

    $udp->set_multicast_loop($on);

The L<set_multicast_loop|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_multicast_loop>
method turns the multicast loopback flag on or off.

=head2 set_multicast_ttl

    $udp->set_multicast_ttl($ttl);

The L<set_multicast_ttl|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_multicast_ttl>
method sets the time-to-live of transmitted multicast packets.

=head2 set_multicast_interface

    $udp->set_multicast_interface($ifaddr);

The L<set_multicast_interface|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_multicast_interface>
method sets the interface address to send or receive data on. The interface
address is specified in a plain byte string.

=head2 set_membership

    $udp->set_membership($mcaddr, $ifaddr, $membership);

The L<set_membership|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_membership>
method joins or leaves a multicast group. C<$membership> should be one of the
exported constants C<UV_JOIN_GROUP> or C<UV_LEAVE_GROUP>. The group and
interface addresses are specified in plain byte strings.

=head2 set_source_membership

    $udp->set_source_membership($mcaddr, $ifaddr, $srcaddr, $membership);

The L<set_source_membership|http://docs.libuv.org/en/v1.x/udp.html#c.uv_udp_set_source_membership>
method joins or leaves a source-specific multicast group. C<$membership>
should be one of the exported constants C<UV_JOIN_GROUP> or C<UV_LEAVE_GROUP>.
The group, interface, and source addresses are specified in plain byte
strings.

=head2 get_send_queue_size

=head2 get_send_queue_count

    $size  = $udp->get_send_queue_size;
    $count = $udp->get_send_queue_count;

Returns the total size and current count of items in the send queue.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
