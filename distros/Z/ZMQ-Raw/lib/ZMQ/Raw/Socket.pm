package ZMQ::Raw::Socket;
$ZMQ::Raw::Socket::VERSION = '0.31';
use strict;
use warnings;
use Carp;
use ZMQ::Raw;

sub CLONE_SKIP { 1 }

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&ZMQ::Raw::Socket::_constant not defined" if $constname eq '_constant';
    my ($error, $val) = _constant ($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

=head1 NAME

ZMQ::Raw::Socket - ZeroMQ Socket class

=head1 VERSION

version 0.31

=head1 DESCRIPTION

A L<ZMQ::Raw::Socket> represents a ZeroMQ socket.

=head1 SYNOPSIS

	use ZMQ::Raw;

	# receive a single message-part
	my $msg = $socket->recvmsg();

	# receive all message parts
	my @msgs = $socket->recvmsg();

	# send multiple message parts
	$socket->sendmsg ('hello', 'world'); # flags cannot be used here

	# or
	my $msg1 = ZMQ::Raw::Message->new;
	$msg1->data ('hello');

	my $msg2 = ZMQ::Raw::Message->new;
	$msg2->data ('world');
	$socket->sendmsg ($msg1, $msgs2, 0); # flags can be used here

=head1 METHODS

=head2 new( $context, $type )

Create a new ZeroMQ socket with the specified C<$context>. C<$type> specifies
the socket type, which determines the semantics of communication over the
socket.

=head2 bind( $endpoint )

Bind the socket to a local endpoint which accepts incoming connections. The
endpoint is a string consisting of a transport:// followed by an address. The
transport specifies the underlying protocol to use, whereas the address
specifies the transport-specific address to bind to. The following transports
are provided:

=over 4

=item * "tcp"

unicast transport using TCP

=item * "ipc"

local inter-process communication transport

=item * "inproc"

local in-process (inter-thread) communication transport

=item * "pgm,epgm"

reliable multicast transport using PGM

=item * "vmci"

virtual machine communications interface (VMCI)

=back

=head2 unbind( $endpoint )

Unbind the socket from the endpoint.

=head2 connect( $endpoint )

Connect the socket to an endpoint which accepts incoming connections.

=head2 disconnect( $endpoint )

Disconnect the socket from the endpoint. Any outstanding messages physically
received from the network but not yet received by the application will be
discarded.

=head2 send( $buffer, $flags = 0)

Queue a message created from C<$buffer>. C<$flags> defaults to C<0> but may
be a combination of:

=over 4

=item * C<ZMQ::Raw-E<gt>ZMQ_DONTWAIT>

Perform the operation in non-blocking mode. This method will return
C<undef> if the message cannot be sent immediately.

=item * C<ZMQ::Raw-E<gt>ZMQ_SNDMORE>

The message is part of a multi-part message and further message parts are to
follow.

=back

This method may return C<undef> (or an empty list if called in list context) if
the system call was interrupt or if the operation cannot be completed
immediately, after which it may be reattempted.

=head2 close( )

Close the socket. Any outstanding messages physically received from the network
but not yet received by the application will be discarded.

=head2 monitor( $endpoint, $events)

Track socket events. Each call to this method creates a C<ZMQ_PAIR> socket and
binds that to the specified inproc C<$endpoint>. In order to collect socket
events, you must create your own C<ZMQ_PAIR> socket and connect it to the
C<$endpoint>.

=head2 sendmsg( @msgs, $flags = 0)

Queue C<@msgs> to be sent. Each message in C<@msgs> that is a L<C<ZMQ::Raw::Message>>
is still valid after this call, that is, they may be reused. Each item in C<@msgs>
may either be a L<C<ZMQ::Raw::Message>> object or a "normal" perl scalar. The
C<$flags> parameter is only available if all items in C<@msgs> are L<C<ZMQ::Raw::Message>>
objects. See the SYNOPSIS for usage examples.

This method may return C<undef> (or an empty list if called in list context) if
the system call was interrupt or if the operation cannot be completed
immediately, after which it may be reattempted.

=head2 recv( $flags = 0)

Receive a message. If there are no messages available the method will block
until the request can be satisfied unless the C<ZMQ_DONTWAIT> flag is specified.
If a message is not available and C<ZMQ_DONTWAIT> has been specified, this
method will return C<undef> immediately. If called in list context, this method
will return each part of the message as a scalar item. In scalar context, each
part of the message will be concatenated into a single scalar item.

This method may return C<undef> (or an empty list if called in list context) if
the system call was interrupt or if the operation cannot be completed
immediately, after which it may be reattempted.

=head2 recvmsg( $flags = 0)

Receive a message part or multiple messages parts if called in list context.
Returns a L<C<ZMQ::Raw::Message>> object or an array of object.

This method may return C<undef> (or an empty list if called in list context) if
the system call was interrupt or if the operation cannot be completed
immediately, after which it may be reattempted.

=head2 setsockopt( $option, $value )

Set a socket option.

=head2 join( $group )

Join a group.

=head2 leave( $group )

Leave a group.

=head1 CONSTANTS

=head2 ZMQ_AFFINITY

=head2 ZMQ_IDENTITY

=head2 ZMQ_SUBSCRIBE

=head2 ZMQ_UNSUBSCRIBE

=head2 ZMQ_RATE

=head2 ZMQ_RECOVERY_IVL

=head2 ZMQ_SNDBUF

=head2 ZMQ_RCVBUF

=head2 ZMQ_RCVMORE

=head2 ZMQ_FD

=head2 ZMQ_EVENTS

=head2 ZMQ_TYPE

=head2 ZMQ_LINGER

=head2 ZMQ_RECONNECT_IVL

=head2 ZMQ_BACKLOG

=head2 ZMQ_RECONNECT_IVL_MAX

=head2 ZMQ_MAXMSGSIZE

=head2 ZMQ_SNDHWM

=head2 ZMQ_RCVHWM

=head2 ZMQ_MULTICAST_HOPS

=head2 ZMQ_RCVTIMEO

=head2 ZMQ_SNDTIMEO

=head2 ZMQ_LAST_ENDPOINT

=head2 ZMQ_ROUTER_MANDATORY

=head2 ZMQ_TCP_KEEPALIVE

=head2 ZMQ_TCP_KEEPALIVE_CNT

=head2 ZMQ_TCP_KEEPALIVE_IDLE

=head2 ZMQ_TCP_KEEPALIVE_INTVL

=head2 ZMQ_IMMEDIATE

=head2 ZMQ_XPUB_VERBOSE

=head2 ZMQ_ROUTER_RAW

=head2 ZMQ_IPV6

=head2 ZMQ_MECHANISM

=head2 ZMQ_PLAIN_SERVER

=head2 ZMQ_PLAIN_USERNAME

=head2 ZMQ_PLAIN_PASSWORD

=head2 ZMQ_CURVE_SERVER

=head2 ZMQ_CURVE_PUBLICKEY

=head2 ZMQ_CURVE_SECRETKEY

=head2 ZMQ_CURVE_SERVERKEY

=head2 ZMQ_PROBE_ROUTER

=head2 ZMQ_REQ_CORRELATE

=head2 ZMQ_REQ_RELAXED

=head2 ZMQ_CONFLATE

=head2 ZMQ_ZAP_DOMAIN

=head2 ZMQ_ROUTER_HANDOVER

=head2 ZMQ_TOS

=head2 ZMQ_CONNECT_RID

=head2 ZMQ_GSSAPI_SERVER

=head2 ZMQ_GSSAPI_PRINCIPAL

=head2 ZMQ_GSSAPI_SERVICE_PRINCIPAL

=head2 ZMQ_GSSAPI_PLAINTEXT

=head2 ZMQ_HANDSHAKE_IVL

=head2 ZMQ_SOCKS_PROXY

=head2 ZMQ_XPUB_NODROP

=head2 ZMQ_BLOCKY

=head2 ZMQ_XPUB_MANUAL

=head2 ZMQ_XPUB_WELCOME_MSG

=head2 ZMQ_STREAM_NOTIFY

=head2 ZMQ_INVERT_MATCHING

=head2 ZMQ_HEARTBEAT_IVL

=head2 ZMQ_HEARTBEAT_TTL

=head2 ZMQ_HEARTBEAT_TIMEOUT

=head2 ZMQ_XPUB_VERBOSER

=head2 ZMQ_CONNECT_TIMEOUT

=head2 ZMQ_TCP_MAXRT

=head2 ZMQ_THREAD_SAFE

=head2 ZMQ_MULTICAST_MAXTPDU

=head2 ZMQ_VMCI_BUFFER_SIZE

=head2 ZMQ_VMCI_BUFFER_MIN_SIZE

=head2 ZMQ_VMCI_BUFFER_MAX_SIZE

=head2 ZMQ_VMCI_CONNECT_TIMEOUT

=head2 ZMQ_USE_FD

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Socket
