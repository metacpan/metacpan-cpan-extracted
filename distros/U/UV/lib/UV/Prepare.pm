package UV::Prepare;

our $VERSION = '1.903';

use strict;
use warnings;
use Carp ();
use parent 'UV::Handle';

sub start {
    my $self = shift;
    if (@_) {
        $self->on('prepare', shift);
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

UV::Prepare - Prepare handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  # A new handle will be initialized against the default loop
  my $prepare = UV::Prepare->new();

  # Use a different loop
  my $loop = UV::Loop->new(); # non-default loop
  my $prepare = UV::Prepare->new(
    loop => $loop,
    on_close => sub {say "close!"},
    on_prepare => sub {say "prepare!"},
  );

  # setup the handle's callback:
  $prepare->on(prepare => sub {say "We're prepared!!!"});

  # start the handle
  $prepare->start();
  # or, with an explicit callback defined
  $prepare->start(sub {say "override any other callback we already have"});

  # stop the handle
  $prepare->stop();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's prepare|http://docs.libuv.org/en/v1.x/prepare.html> handle.

Prepare handles will run the given callback once per loop iteration, right
before polling for i/o.

=head1 EVENTS

L<UV::Prepare> inherits all events from L<UV::Handle> and also makes the
following extra events available.

=head2 prepare

    $prepare->on(prepare => sub { my $invocant = shift; say "We are here!"});
    my $count = 0;
    $prepare->on(prepare => sub {
        my $invocant = shift; # the handle instance this event fired on
        if (++$count > 2) {
            say "We've been called twice. stopping!";
            $invocant->stop();
        }
    });

When the event loop runs and the handle is ready, this event will be fired.
L<UV::Prepare> handles will run the given callback once per loop iteration,
right before polling for i/o.

=head1 METHODS

L<UV::Prepare> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 new

    my $prepare = UV::Prepare->new();
    # Or tell it what loop to initialize against
    my $prepare = UV::Prepare->new(
        loop => $loop,
        on_close => sub {say "close!"},
        on_prepare => sub {say "prepare!"},
    );

This constructor method creates a new L<UV::Prepare> object and
L<initializes|http://docs.libuv.org/en/v1.x/prepare.html#c.uv_prepare_init> the
handle with the given L<UV::Loop>. If no L<UV::Loop> is provided, then the
L<UV::Loop/"default_loop"> is assumed.

=head2 start

    # start the handle with the callback we supplied with ->on() or with no cb
    $prepare->start();

    # pass a callback for the "idle" event
    $prepare->start(sub {say "yay"});
    # providing the callback above completely overrides any callback previously
    # set in the ->on() method. It's equivalent to:
    $prepare->on(idle => sub {say "yay"});
    $prepare->start();

The L<start|http://docs.libuv.org/en/v1.x/prepare.html#c.uv_prepare_start> method
starts the handle.

=head2 stop

    $prepare->stop();

The L<stop|http://docs.libuv.org/en/v1.x/prepare.html#c.uv_prepare_stop> method
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
