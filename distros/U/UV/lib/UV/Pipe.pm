package UV::Pipe;

our $VERSION = '1.906';

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

1;

__END__

=encoding utf8

=head1 NAME

UV::Pipe - Pipe stream handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  # A new stream handle will be initialised against the default loop
  my $pipe = UV::Pipe->new;

  $pipe->connect("server.sock", sub {
    say "Connected!";

    $pipe->write("Hello, server!\n");
  });

  # set up the data read callback
  $pipe->on(read => sub {
    my ($self, $err, $buf) = @_;
    say "More data: $buf";
  });
  $pipe->read_start();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's pipe|http://docs.libuv.org/en/v1.x/pipe.html> stream handle.

Pipe handles represent a FIFO or UNIX ("local") socket.

=head1 EVENTS

L<UV::Pipe> inherits all events from L<UV::Stream> and L<UV::Handle>.

=head1 METHODS

L<UV::Pipe> inherits all methods from L<UV::Stream> and L<UV::Handle> and also
makes the following extra methods available.

=head2 open

    $pipe->open($fh);

The L<open|http://docs.libuv.org/en/v1.x/pipe.html#c.uv_pipe_open> method
associates the pipe with an existing filehandle already opened by the process.

=head2 bind

    $pipe->bind($path);

The L<bind|http://docs.libuv.org/en/v1.x/pipe.html#c.uv_pipe_bind> method
associates the pipe with a UNIX socket path or named filehandle, which will be
created on the filesystem.

=head2 connect

    $pipe->connect($path, sub {
        my ($err) = @_;
        die "Cannot connect pipe - $err\n" if $err;

        say "The pipe is now connected";
    });

The L<connect|http://docs.libuv.org/en/v1.x/pipe.html#c.uv_pipe_connect> method
requests that the pipe be connected a server found on the given path.

On completion the callback is invoked. It is passed C<undef> on success, or an
error value on failure. This error value can be compared numerically to one of
the C<UV_E*> constants, or printed as a string to give a message.

=head2 getpeername

    my $path = $pipe->getpeername;

The L<getpeername|http://docs.libuv.org/en/v1.x/pipe.html#c.uv_pipe_getpeername>
method returns the filesystem path to which this pipe handle is connected.

=head2 getsockname

    my $path = $pipe->getsockname;

The L<getsockname|http://docs.libuv.org/en/v1.x/pipe.html#c.uv_pipe_getsockname>
method returns the filesystem path on which this pipe server handle is
listening for incoming connections.

=head2 chmod

    $pipe->chmod($flags);

The L<chmod|http://docs.libuv.org/en/v1.x/pipe.html#c.uv_pipe_chmod> method
sets the filesystem permissions on the named pipe or socket to allow access by
other users. C<$flags> should be a bitmask of C<UV_READABLE> or C<UV_WRITABLE>.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
