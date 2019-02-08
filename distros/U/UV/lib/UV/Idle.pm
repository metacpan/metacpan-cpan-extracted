package UV::Idle;

our $VERSION = '1.000009';

use strict;
use warnings;
use Exporter qw(import);
use parent 'UV::Handle';

use Carp ();

sub _after_new {
    my ($self, $args) = @_;
    # add to the default set of events for a Handle object
    $self->_add_event('idle', $args->{on_idle});

    my $err = do { #catch
        local $@;
        eval { $self->_init($self->{_loop}); 1; }; #try
        $@;
    };
    Carp::croak($err) if $err; # throw
    return $self;
}

sub start {
    my $self = shift;
    if (@_) {
        $self->on('idle', shift);
    }
    my $res;
    my $err = do { #catch
        local $@;
        eval {
            $res = $self->_start();
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

UV::Idle - Idle handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  # A new handle will be initialized against the default loop
  my $idle = UV::Idle->new();

  # Use a different loop
  my $loop = UV::Loop->new(); # non-default loop
  my $idle = UV::Idle->new(
    loop => $loop,
    on_alloc => sub {say "alloc!"},
    on_close => sub {say "close!"},
    on_idle => sub {say "idle!"},
  );

  # setup the idle callback:
  $idle->on(idle => sub {say "We're IDLING!!!"});

  # start the handle
  $idle->start();
  # or, with an explicit callback defined
  $idle->start(sub {say "override any 'idle' callback we already have"});

  # stop the check
  $idle->stop();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's idle|http://docs.libuv.org/en/v1.x/idle.html> handle.

Idle handles will run the given callback once per loop iteration, right before
the L<UV::Prepare> handles.

B<* Note:> The notable difference with L<UV::Prepare> handles is that when
there are active L<UV::Idle> handles, the loop will perform a zero timeout poll
instead of blocking for i/o.

=head1 EVENTS

L<UV::Idle> inherits all events from L<UV::Handle> and also makes the
following extra events available.

=head2 idle

    $handle->on(idle => sub { my $invocant = shift; say "We are idling!"});
    my $count = 0;
    $handle->on("idle", sub {
        my $invocant = shift; # the handle instance this event fired on
        if (++$count > 2) {
            say "We've idled twice. stopping!";
            $invocant->stop();
        }
    });

When the event loop runs and the idle is ready, this event will be fired.

B<* Note:> Despite the name, L<UV::Idle> handles will get their callbacks
called on every loop iteration, not when the loop is actually "idle".


=head1 METHODS

L<UV::Idle> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 new

    my $idle = UV::Idle->new();
    # Or tell it what loop to initialize against
    my $idle = UV::Idle->new(
        loop => $loop,
        on_alloc => sub {say "alloc!"},
        on_close => sub {say "close!"},
        on_idle => sub {say "idle!"},
    );

This constructor method creates a new L<UV::Idle> object and
L<initializes|http://docs.libuv.org/en/v1.x/idle.html#c.uv_idle_init> the
handle with the given L<UV::Loop>. If no L<UV::Loop> is provided, then the
L<UV::Loop/"default_loop"> is assumed.

=head2 start

    # start the handle with the callback we supplied with ->on() or with no cb
    $idle->start();

    # pass a callback for the "idle" event
    $idle->start(sub {say "yay"});
    # providing the callback above completely overrides any callback previously
    # set in the ->on() method. It's equivalent to:
    $idle->on(idle => sub {say "yay"});
    $idle->start();

The L<start|http://docs.libuv.org/en/v1.x/idle.html#c.uv_idle_start> method
starts the handle.

=head2 stop

    $idle->stop();

The L<stop|http://docs.libuv.org/en/v1.x/idle.html#c.uv_idle_stop> method
stops the handle. The callback will no longer be called.

=head1 AUTHOR

Chase Whitener <F<capoeirab@cpan.org>>

=head1 AUTHOR EMERITUS

Daisuke Murase <F<typester@cpan.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2012, Daisuke Murase.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
