package UV::Signal;

our $VERSION = '2.000';

use strict;
use warnings;
use Carp ();
use parent 'UV::Handle';

our @EXPORT_OK = (@UV::Signal::EXPORT_XS,);

sub _new_args {
    my ($class, $args) = @_;
    my $signum = delete $args->{signal} // delete $args->{single_arg};
    return ($class->SUPER::_new_args($args), $signum);
}

sub start {
    my $self = shift;
    if (@_) {
        $self->on('signal', shift);
    }
    $self->_start;
}

1;

__END__

=encoding utf8

=head1 NAME

UV::Signal - Signal handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;
  use UV::Signal qw(SIGINT);

  # A new handle will be initialised against the default loop
  my $signal = UV::Signal->new(signal => SIGINT);

  # Use a different loop
  my $loop = UV::Loop->new(); # non-default loop
  my $signal = UV::Signal->new(
    loop => $loop,
    on_close => sub {say "close!"},
    on_signal => sub {say "signal!"},
  );

  # setup the signal callback:
  $signal->on(signal => sub {say "We get SIGNAL!!!"});

  # start the check
  $signal->start();
  # or, with an explicit callback defined
  $signal->start(sub {say "override any 'signal' callback we already have"});

  # stop the signal
  $signal->stop();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's signal|http://docs.libuv.org/en/v1.x/signal.html> handle.

Signal handles will run the given callback on receipt of the specified signal.

=head1 EVENTS

L<UV::Signal> inherits all events from L<UV::Handle> and also makes the
following extra events available.

=head2 signal

    $signal->on("signal", sub {
        my ($invocant, $signum) = @_;
        say "We get signal";
    });

When the event loop runs and the signal is received, this event will be fired.

=head1 METHODS

L<UV::Signal> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 new

    my $signal = UV::Signal->new(signal => SIGFOO);
    # Or tell it what loop to initialize against
    my $signal = UV::Signal->new(
        loop=> $loop,
        on_close => sub {say 'close!'},
        on_signal => sub {say 'signal!'},
    );

This constructor method creates a new L<UV::Signal> object and
L<initializes|http://docs.libuv.org/en/v1.x/signal.html#c.uv_signal_init> the
handle with the given L<UV::Loop>. If no L<UV::Loop> is provided then the
L<UV::Loop/"default_loop"> is assumed.

=head2 start

    # start the handle with the callback we supplied with ->on() or with no cb
    $signal->start();

    # pass a callback for the "signal" event
    $signal->start(sub {say "yay"});
    # providing the callback above completely overrides any callback previously
    # set in the ->on() method. It's equivalent to:
    $signal->on(signal => sub {say "yay"});
    $signal->start();

The L<start|http://docs.libuv.org/en/v1.x/signal.html#c.uv_signal_start> method
starts the handle.

Note that the signal number is given to the constructor, not the C<start>
method.

Returns the C<$signal> instance itself.

=head2 stop

    $signal->stop();

The L<stop|http://docs.libuv.org/en/v1.x/signal.html#c.uv_signal_stop> method
stops the handle. The callback will no longer be called.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
