package ZeroMQ::Poller::Timer;

use strict;
use warnings;

our $VERSION = '0.01';

use threads;
use ZeroMQ qw/ ZMQ_POLLIN ZMQ_PAIR /;

my $zmq_ctxt = ZeroMQ::Context->new();
my $testmode = 0;

# Nope, not using Moose or even Class::Accessor 'antlers'
# for this first pass. It's a lite weight little module
# and I'd like to keep it that way for now.

sub new {
    my $class = shift;
    my $self  = {@_};
    $testmode ||= $self->{'test'};

    if ( !$self->{'name'} ) {
        _pe("constuctor requires a 'name' field.");
        return;
    }

    if ( !defined $self->{'after'} ) {
        _pe("constructor requires a 'after' field.");
        return;
    }

    if ( $self->{'after'} !~ /^\d+$/ ) {
        _pe("the 'after' field must be an integer.");
        return;
    }

    if ( defined $self->{'interval'} && $self->{'interval'} !~ /^\d+$/ ) {
        _pe("the 'interval' field must be an integer.");
        return;
    }

    $self->{'_addr'} = "inproc://" . $self->{'name'};
    $self->{'_sock'} = $zmq_ctxt->socket(ZMQ_PAIR);
    $self->{'_sock'}->bind( $self->{'_addr'} );

    my $obj = bless $self, $class;

    $obj->start unless $self->{'pause'};

    return $obj;
}

sub start {
    my $self = shift;
    my $thread = threads->create( \&_timer, $self );

    $thread->detach;
}

sub name { shift->{'name'} }

sub socket { shift->{'_sock'} }

sub reset { shift->socket->recv }

sub poll_hash {
    my $self = shift;

    return {
        name   => $self->name,
        socket => $self->socket,
        events => ZMQ_POLLIN,
    };
}

sub _timer {
    my $self  = shift;
    my $after = $self->{'after'};
    my $int   = $self->{'interval'};
    my $sock  = $zmq_ctxt->socket(ZMQ_PAIR);

    $sock->connect( $self->{'_addr'} );

    sleep $after;

    if ( !$int ) {
        $sock->send(1);
        return;
    }

    while (1) {
        $sock->send(1);
        sleep $int;
    }
}

# '_pe' is short for 'print error'. te he.
sub _pe {
    return if $testmode;
    print STDERR __PACKAGE__ . ': ' . (shift) . "\n";
}

1;

__END__

=head1 NAME

ZeroMQ::Poller::Timer - Simple timer for use with ZeroMQ::Poller

=head1 SYNOPSIS

  use ZeroMQ::Poller::Timer;

  my $timer = ZeroMQ::Poller::Timer->new(
      name     => 'my_timer',    # Required
      after    => $seconds,      # Required
      interval => $seconds,
      pause    => [1|0],         # Defaults to 0
  );

=head1 DESCRIPTION

ZeroMQ::Poller waits on ZeroMQ sockets for events, and if you're writing
a daemon you would usually have it do this in an infinite loop. However,
if nothing is happening on those sockets then ZeroMQ::Poller just blocks
on it's C<poll()> method indefinitely. Daemons might periodically want to
do things, like reload configuration files, talk to databases, or process
jobs that didn't succeed the first time.

Currently, ZeroMQ::Poller has no built in functionality to let you
periodically break out of the the C<poll()> and do work. So this is my
attempt at adding periodic timer functionality to ZeroMQ::Poller, using
ZeroMQ.

B<ZeroMQ::Poller::Timer> is a simple, AnyEvent-like timer for use with
ZeroMQ::Poller. Like an AnyEvent timer you can set each timer to fire
off once, or at intervals. It currently does not support a callback
feature, and might never. The timer is simply a way to make it possible
to periodically break out of the blocking call to C<poll()> so you can
do other daemony stuff.

=head1 FULL EXAMPLE

  use ZeroMQ::Poller::Timer;
  use ZeroMQ qw/ ZMQ_POLLIN /;

  my $timer = ZeroMQ::Poller::Timer->new(
      name     => 'my_timer',
      after    => $seconds,
      interval => $seconds,
  );

  my $poller = ZeroMQ::Poller->new(
      $timer->poll_hash,

      {
          # Another poll item
      },
  );

  while (1) {
      $poller->poll;

      if ($poller->has_event($timer->name)) {
          $timer->reset;  # This is important!

          # Do stuff...
      }
      if ($poller->has_event('other_item')) {
          # ...
      }
  }

=head1 CONSTRUCTOR ARGUMENTS

=over 4

=item * I<name>     (B<required>)

This is the unique name for this timer. It will be used in your poll loop
to identify which event block to execute. (See FULL EXAMPLE above and
METHODS below).

=item * I<after>    (B<required>)

Number of seconds after which to execute the timer. If you want to start
running the timer immediately set this value to 0 (zero).

=item * I<interval>

To set up a periodic timer (which most of you will be wanting to do) use
this field. It is the number of seconds to wait before firing the timer.

=item * I<pause>

By default ZeroMQ::Poller::Timer will create the thread timer at constructor
instantion. To delay this set the B<pause> field to a true value, like 1!

If you do this B<you must> also make sure to call the C<start()> method before
you land in your poll loop. Otherwise this was all for not.

=back

=head1 METHODS

=head2 name()

Return the name of the timer you passed into the constructor. You'll use
this when calling the C<< $poller->has_event() >> method inside your polling
loop:

  if ($poller->has_event($timer->name)) {
      # ...
  }

or when you manually declare the poll item hash in the ZeroMQ::Poller
constructor (see C<sock()> below).

=head2 sock()

Return the ZeroMQ socket for the timer. This can be used if you manually
declare the poll item hash in the ZeroMQ::Poller constructor. (i.e. you
decide not to use the C<poll_hash()> method):

  my $poller = ZeroMQ::Poller->new(
      {
          name   => $timer->name,
          sock   => $timer->sock,
          events => ZMQ_POLLIN,        
      },
  );

=head2 start()

If you had passed a true value into the constructor for the 'pause' field
then you need to call C<start()> to start your timer. The timer thread will
not be created until this is called, so make sure you do it before you enter
your infinite poll loop.

=head2 reset()

When your timer fires off and you enter the C<< if ($poller->has_event(...)) >>
block inside your infinite loop you need to reset the timer. This is really
just a convience method and is the same as doing the following:

  $timer->socket->recv;

When you fall into a C<has_event()> block you'd need to make a call to a
C<revc()> anyways, so this doesn't add any overhead... just syntatic sugar.

=head2 poll_hash()

This is another convience method for you and is best explained by example.
The following two instantiations are identical:

  my $poller = ZeroMQ::Poller->new(
      $timer->poll_hash,
  );

and

  my $poller = ZeroMQ::Poller->new(
      {
          name   => $timer->name,
          socket => $timer->socket,
          events => ZMQ_POLLIN,
      },
  );

=head1 NOTES

This module uses perl L<threads>. If you're using ZeroMQ to begin with then
threads shouldn't be a concern for you.

Also, it does not have any external module dependencies, other than ZeroMQ,
as I would like to keep it as lite and as simple as possible. 

=head1 CAVEATS

ZeroMQ::Poller::Timer uses the ZMQ_PAIR pattern, which for a long while
was considered experimental, though it seems to be stable now. It's main
use is for efficient multithreading communication, which is what we're
using it for here. ZMQ_PAIR sockets are meant to be used in a controlled,
stable environment (i.e. not interprocess) and do not auto-reconnect.

If you are having any issues using ZeroMQ::Poller::Timer in your application
please file a bug report on github at:

L<https://github.com/jconerly/ZeroMQ-Poller-Timer>

=head1 SEE ALSO

L<ZeroMQ>, L<ZeroMQ::Poller>, L<AnyEvent>

L<ZeroMQ::Poller::Timer>

=head1 AUTHOR

James Conerly C<< <james at jamesconerly.com> >>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic>.

=cut
