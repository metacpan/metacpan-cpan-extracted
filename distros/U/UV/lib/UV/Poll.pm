package UV::Poll;

our $VERSION = '1.000009';

use strict;
use warnings;
use Carp ();
use Exporter qw(import);
use parent 'UV::Handle';

our @EXPORT_OK = (@UV::Poll::EXPORT_XS,);

sub _after_new {
    my ($self, $args) = @_;
    $self->_add_event('poll', $args->{on_poll});
    my $socket = (exists($args->{socket}) && defined($args->{socket})) ? 1 : 0;

    my $fd;
    for my $key (qw(fd fh socket single_arg)) {
        if (defined($fd = $args->{$key})) {
            if (CORE::ref($fd) eq 'GLOB' || CORE::ref($fd) =~ /^IO::Socket/) {
                $fd = fileno($fd);
                last;
            }
            elsif (!CORE::ref($fd) && $fd =~ /\A[0-9]+\z/) {
                last;
            }
            else {
                $fd = undef;
            }
        }
    }
    unless (defined($fd)) {
        Carp::croak("No file or socket descriptor provided");
    }

    my $err = do { #catch
        local $@;
        eval { $self->_init($fd, $self->{_loop}); 1; }; #try
        $@;
    };
    Carp::croak($err) if $err; # throw
    return $self;
}

sub start {
    my $self = shift;
    Carp::croak("Can't start a closed handle") if $self->closed();

    my $events = shift(@_) || UV::Poll::UV_READABLE;

    if (@_) {
        $self->on('poll', shift);
    }
    my $res;
    my $err = do { #catch
        local $@;
        eval {
            $res = $self->_start($events);
            1;
        }; #try
        $@;
    };
    Carp::croak($err) if $err; # throw
    return $res;
}

1;

__END__

=encoding utf8

=head1 NAME

UV::Poll - Poll handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  # assume we have a file/IO handle from somewhere
  # A new handle will be initialized against the default loop
  my $poll = UV::Poll->new(fd => fileno($handle));

  # Use a different loop
  my $loop = UV::Loop->new(); # non-default loop
  my $poll = UV::Poll->new(
    fd => fileno($handle),
    loop => $loop,
    on_alloc => sub {say "alloc!"},
    on_close => sub {say "close!"},
    on_poll => sub {say "poll!"},
  );

  # Create a new poll on a socket handle
  my $socket = IO::Socket::INET->new(Type => SOCK_STREAM);
  my $poll = UV::Poll->new(
    socket => 1,
    fd => fileno($socket),
    on_alloc => sub {say "alloc!"},
    on_close => sub {say "close!"},
    on_poll => sub {say "poll!"},
  );

  # setup the handle's callback:
  $poll->on(poll => sub {"We're prepared!!!"});

  # start the handle
  $poll->start(UV::Poll::UV_READABLE);
  # or, with an explicit callback defined
  $poll->start(UV::Poll::UV_READABLE, sub {
    my ($invocant, $status, $events) = @_;
    say "override any other callback we already have";
  });

  # stop the handle
  $poll->stop();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's prepare|http://docs.libuv.org/en/v1.x/poll.html> handle.

Poll handles are used to watch file descriptors for readability, writability
and disconnection similar to the purpose of
L<poll(2)|http://linux.die.net/man/2/poll>.

The purpose of poll handles is to signal us about socket status changes. Using
L<UV::Poll> for any other purpose is not recommended; L<UV::TCP>, L<UV::UDP>,
etc. provide an implementation that is faster and more scalable than what can
be achieved with L<UV::Poll>, especially on Windows.

It is possible that L<UV::Poll> handles occasionally signal that a file
descriptor is readable or writable even when it isn't. The user should
therefore always be prepared to handle C<EAGAIN> or equivalent when it attempts
to read from or write to the C<fd>.

It is not okay to have multiple active L<UV::Poll> handles for the same socket,
this can cause libuv to busyloop or otherwise malfunction.

The user should not close a file descriptor while it is being polled by an
active L<UV::Poll> handle. This can cause the handle to report an error, but it
might also start polling another socket. However the C<fd> can be safely closed
immediately after a call to L<UV::Poll/"stop"> or L<UV::Handle/"close">.

B<* Note:> On Windows, only sockets can be polled with L<UV::Poll> handles.
On Unix, any file descriptor that would be accepted by
L<poll(2)|http://linux.die.net/man/2/poll> can be used.

B<* Note:> On AIX, watching for disconnection is not supported.

=head1 CONSTANTS

=head2 POLL EVENT CONSTANTS

=head3 UV_READABLE

=head3 UV_WRITABLE

=head3 UV_DISCONNECT

=head3 UV_PRIORITIZED

=head1 EVENTS

L<UV::Poll> inherits all events from L<UV::Handle> and also makes the
following extra events available.

=head2 poll

    $poll->on(poll => sub {
        my ($invocant, $status, $events) = @_;
        say "We are here!";
    });
    my $count = 0;
    $poll->on(poll => sub {
        my $invocant = shift; # the handle instance this event fired on
        if (++$count > 2) {
            say "We've been called twice. stopping!";
            $invocant->stop();
        }
    });

When the event loop runs and the handle is ready, this event will be fired.
L<UV::Poll> handles will run the given callback once per loop iteration,
right before polling for i/o.

=head1 METHODS

L<UV::Poll> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 new

    use IO::Socket::INET;
    use UV ();
    use UV::Loop ();
    use UV::Poll qw(UV_READABLE UV_WRITABLE);

    my $poll = UV::Poll->new(fd => fileno($some_handle));
    # Or tell it what loop to initialize against
    my $poll = UV::Poll->new(fd => fileno($some_handle), loop => $loop);

    my $socket = IO::Socket::INET->new(Type => SOCK_STREAM);

    my $poll = UV::Poll->new(socket => 1, fd => fileno($socket));
    # or another loop
    my $poll = UV::Poll->new(
        socket => 1.
        fd => fileno($socket),
        loop => $some_loop,
        on_alloc => sub {say "alloc!"},
        on_close => sub {say "close!"},
        on_poll => sub {say "poll!"},
    );

    $poll->run(UV_READABLE | UV_WRITABLE, sub { ... });

This constructor method creates a new L<UV::Poll> object instance. It
initializes the handle with either the given L<UV::Loop> or the
L<default loop|UV::Loop/"default">.

Then initialization happens with
L<init|http://docs.libuv.org/en/v1.x/poll.html#c.uv_poll_init> or
L<init_socket|http://docs.libuv.org/en/v1.x/poll.html#c.uv_poll_init_socket>.

B<* Note:> As of libuv v1.2.2: the file descriptor is set to non-blocking mode.

=head2 start

    # Start the handle. By default, we'll:
    # use the UV_READABLE events mask
    # use whatever callback was supplied with ->on(poll => sub {...})
    $poll->start();

    # Pass events
    $poll->start(UV_READABLE | UV_WRITABLE);

    # pass a callback for the "idle" event
    $poll->start(UV_READABLE, sub {say "yay"});
    # providing the callback above completely overrides any callback previously
    # set in the ->on() method. It's equivalent to:
    $poll->on(idle => sub {say "yay"});
    $poll->start(UV_READABLE);

The L<start|http://docs.libuv.org/en/v1.x/poll.html#c.uv_poll_start> method
starts polling the file descriptor. C<events> is a bitmask made up of
C<UV_READABLE>, C<UV_WRITABLE>, C<UV_PRIORITIZED> and C<UV_DISCONNECT>. As soon
as an event is detected, the callback will be called with C<$status> set to
C<0>, and the detected events set on the C<$events> field.

The C<UV_PRIORITIZED> (added in libuv v1.14.0) event is used to watch for
C<sysfs> interrupts or TCP out-of-band messages.

The C<UV_DISCONNECT> (added in libuv v1.9.0) event is optional in the sense
that it may not be reported and the user is free to ignore it, but it can help
optimize the shutdown path because an extra read or write call might be
avoided.

If an error happens while polling, C<$status> will be < 0 and correspond with
one of the C<UV::UV_E*> error codes. The user should not close the socket while
the handle is active. If the user does that anyway, the callback may be called
reporting an error status, but this is not guaranteed.

B<* Note:> Calling C<< $poll->start() >> on a handle that is already active is
fine. Doing so will update the events mask that is being watched for.

B<* Note:> Though C<UV_DISCONNECT> can be set, it is unsupported on AIX and as
such will not be set on the C<$events> field in the callback.

=head2 stop

    $poll->stop();

The L<stop|http://docs.libuv.org/en/v1.x/poll.html#c.uv_poll_stop> method
stops polling the file descriptor. The callback will no longer be called.

=head1 AUTHOR

Chase Whitener <F<capoeirab@cpan.org>>

=head1 AUTHOR EMERITUS

Daisuke Murase <F<typester@cpan.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2012, Daisuke Murase.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
