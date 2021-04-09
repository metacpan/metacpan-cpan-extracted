package UV::TCP;

our $VERSION = '1.907';

use strict;
use warnings;
use Carp ();
use parent 'UV::Stream';

sub open
{
    my $self = shift;
    my ($fh) = @_;
    return $self->_open($fh->fileno);
}

sub close_reset {
    my $self = shift;
    $self->on('close', @_) if @_;

    return if $self->closed || $self->closing;
    $self->stop if $self->can('stop');
    $self->_close_reset;
}

1;

__END__

=encoding utf8

=head1 NAME

UV::TCP - TCP socket handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use Socket;

  # A new stream handle will be initialised against the default loop
  my $tcp = UV::TCP->new;

  $tcp->connect(pack_sockaddr_in(1234, inet_aton("127.0.0.1")), sub {
    say "Connected!";

    $tcp->write("Hello, server!\n");
  });

  # set up the data read callback
  $tcp->on(read => sub {
    my ($self, $err, $buf) = @_;
    say "More data: $buf";
  });
  $tcp->read_start();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's TCP|http://docs.libuv.org/en/v1.x/tcp.html> stream handle.

=head1 EVENTS

L<UV::TCP> inherits all events from L<UV::Stream> and L<UV::Handle>.

=head1 METHODS

L<UV::TCP> inherits all methods from L<UV::Stream> and L<UV::Handle> and also
makes the following extra methods available.

=head2 open

    $tcp->open($fh);

The L<open|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_open> method
associates the TCP handle with an existing filehandle already opened by the
process.

=head2 nodelay

    $tcp->nodelay($enable);

The L<nodelay|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_nodelay> method
controls the C<TCP_NODELAY> socket option.

=head2 keepalive

    $tcp->keepalive($enable, $delay);

The L<keepalive|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_keepalive>
method controls keepalive behaviour on the TCP socket. If the C<$enable>
argument is true then C<$delay> must be supplied; if not it is ignored and may
be absent.

=head2 simultaneous_accepts

    $tcp->simultaneous_accepts($enable);

The L<simultaneous_accepts|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_simultaneous_accepts>
method controls whether asynchronous accept requests are queued by the
operating system.

=head2 bind

    $tcp->bind($addr);

The L<bind|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_bind> method
associates the TCP socket with the given local address.

=head2 connect

    $tcp->connect($addr, sub {
        my ($err) = @_;
        die "Cannot connect TCP socket - $err\n" if $err;

        say "The TCP socket is now connected";
    });

The L<connect|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_connect> method
requests that the TCP socket be connected a server found at the given address.

On completion the callback is invoked. It is passed C<undef> on success, or an
error value on failure. This error value can be compared numerically to one of
the C<UV_E*> constants, or printed as a string to give a message.

=head2 getpeername

    my $addr = $tcp->getpeername;

The L<getpeername|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_getpeername>
method returns a packed sockaddr string containing the address to which this
TCP handle is connected.

=head2 getsockname

    my $addr = $tcp->getsockname;

The L<getsockname|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_getsockname>
method returns a packed sockaddr string containing the address on which this
TCP handle is listening for incoming connections.

=head2 close_reset

    $tcp->close_reset();
    $tcp->close_reset(sub {say "we've closed"});

The L<close_reset|http://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_close_reset>
method requests that the socket be closed with a C<RST> packet. It otherwise
behaves similarly to L<UV::Handle/close>.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
