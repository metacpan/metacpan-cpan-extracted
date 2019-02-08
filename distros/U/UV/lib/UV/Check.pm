package UV::Check;

our $VERSION = '1.000009';

use strict;
use warnings;
use Carp ();
use Exporter qw(import);
use parent 'UV::Handle';

sub _after_new {
    my ($self, $args) = @_;
    $self->_add_event('check', $args->{on_check});
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
        $self->on('check', shift);
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

UV::Check - Check handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  # A new handle will be initialized against the default loop
  my $check = UV::Check->new();

  # Use a different loop
  my $loop = UV::Loop->new(); # non-default loop
  my $check = UV::Check->new(
    loop => $loop,
    on_alloc => sub {say "alloc!"},
    on_close => sub {say "close!"},
    on_check => sub {say "check!"},
  );

  # setup the check callback:
  $check->on(check => sub {say "We're CHECKING!!!"});

  # start the check
  $check->start();
  # or, with an explicit callback defined
  $check->start(sub {say "override any 'check' callback we already have"});

  # stop the check
  $check->stop();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's check|http://docs.libuv.org/en/v1.x/check.html> handle.

Check handles will run the given callback once per loop iteration, right after
polling for i/o.

=head1 EVENTS

L<UV::Check> inherits all events from L<UV::Handle> and also makes the
following extra events available.

=head2 check

    $handle->on(check => sub { my $invocant = shift; say "We are checking!"});
    my $count = 0;
    $handle->on("check", sub {
        my $invocant = shift; # the check instance this event fired on
        if (++$count > 2) {
            say "We've checked twice. stopping!";
            $invocant->stop();
        }
    });

When the event loop runs and the check is ready, this event will be fired.

=head1 METHODS

L<UV::Check> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 new

    my $check = UV::Check->new();
    # Or tell it what loop to initialize against
    my $check = UV::Check->new(
        loop => $loop,
        on_alloc => sub {say "alloc!"},
        on_close => sub {say "close!"},
        on_check => sub {say "check!"},
    );

This constructor method creates a new L<UV::Check> object and
L<initializes|http://docs.libuv.org/en/v1.x/check.html#c.uv_check_init> the
check with the given L<UV::Loop>. If no L<UV::Loop> is provided, then the
L<UV::Loop/"default_loop"> is assumed.

=head2 start

    # start the handle with a callback we supplied with ->on() or with no cb
    $check->start();

    # pass a callback for the "check" event
    $check->start(sub {say "yay"});
    # providing the callback above completely overrides any callback previously
    # set in the ->on() method. It's equivalent to:
    $check->on(check => sub {say "yay"});
    $check->start();

The L<start|http://docs.libuv.org/en/v1.x/check.html#c.uv_check_start> method
starts the check handle.

=head2 stop

    $check->stop();

The L<stop|http://docs.libuv.org/en/v1.x/timer.html#c.uv_timer_stop> method
stops the check handle. The callback will no longer be called.

=head1 AUTHOR

Chase Whitener <F<capoeirab@cpan.org>>

=head1 AUTHOR EMERITUS

Daisuke Murase <F<typester@cpan.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2012, Daisuke Murase.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
