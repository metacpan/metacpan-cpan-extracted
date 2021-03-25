package UV::Stream;

our $VERSION = '1.906';

use strict;
use warnings;
use Carp ();
use parent 'UV::Handle';

sub listen
{
    my $self = shift;
    my ($backlog, $cb) = @_;

    $self->on(connection => $cb) if $cb;
    $self->_listen($backlog);
}

sub accept
{
    my $self = shift;

    my $client = (ref $self)->_new($self->loop);

    $self->_accept($client);

    return $client;
}

1;

__END__

=encoding utf8

=head1 NAME

UV::Stream - Stream handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  # Stream is the superclass of Pipe, TTY and TCP handles

  # TODO

=head1 DESCRIPTION

This module provides an interface to
L<libuv's stream|http://docs.libuv.org/en/v1.x/stream.html>. We will try to
document things here as best as we can, but we also suggest you look at the
L<libuv docs|http://docs.libuv.org> directly for more details on how things
work.

You will likely never use this class directly. You will use the different
stream sub-classes directly. Some of these methods or events will be called
or fired from those sub-classes.

=head1 EVENTS

L<UV::Stream> makes the following extra events available.

=head2 connection

    $stream->on("connection", sub {
        my ($self) = @_;
        my $client = $self->accept;
        ...
    });

The L<connection|http://docs.libuv.org/en/v1.x/stream.html#c.uv_connection_cb>
callback fires when a new connection is received on a listening stream server.

Within the callback you should use L</accept> to obtain the new client stream.

=head2 read

    $stream->on("read", sub {
        my ($self, $status, $buf) = @_;
        say "Received more data: <$buf>";
    });

The L<read|http://docs.libuv.org/en/v1.x/stream.html#c.uv_read_cb> callback
fires whenever there is more incoming data on the stream to be passed to the
application.

=head1 METHODS

L<UV::Stream> makes the following methods available.

=head2 listen

    # start listening with the callback we supplied with ->on()
    $stream->listen($backlog);

    # pass a callback for the "connection" event
    $stream->listen($backlog, sub {
        my $client = $stream->accept;
        say "Received a new connection";
    });

The L<listen|http://docs.libuv.org/en/v1.x/stream.html#c.uv_listen> method
starts a stream server listening for incoming client client connections. The
C<connection> event will be fired each time a new one arrives.

=head2 accept

    my $client = $stream->accept;

The L<accept|http://docs.libuv.org/en/v1.x/stream.html#c.uv_accept> method
prepares a new stream connection to represent the next incoming client
connection that has been received.

=head2 shutdown

    $stream->shutdown(sub {
        say "Stream is now shut down";
    });

The L<shutdown|http://docs.libuv.org/en/v1.x/stream.html#c.uv_shutdown> method
stops the writing half of the socket once all of the currently-pending writes
have been flushed.

=head2 read_start

    # start reading with the callback we supplied with ->on()
    $stream->read_start;

The L<read_start|http://docs.libuv.org/en/v1.x/stream.html#c.uv_read_start>
starts the reading side of the stream handle. The C<read> event callback will
be invoked whenever there is new data to be given to the application.

Returns the C<$stream> instance itself.

=head2 read_stop

    $stream->read_stop;

The L<read_stop|http://docs.libuv.org/en/v1.x/stream.html#c.uv_read_stop>
method stops the reading side of the stream handle.

=head2 write

    $stream->write($s, sub {
        say "Data has now been written to the stream";
    });

The L<write|http://docs.libuv.org/en/v1.x/stream.html#c.uv_write> method
sends more data through the writing side of the stream. The callback argument
will be invoked when the data has been flushed to the filehandle.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
