package UV::Async;

our $VERSION = '2.000';

use strict;
use warnings;
use parent 'UV::Handle';

use Carp ();

1;

__END__

=encoding utf8

=head1 NAME

UV::Async - Async notification handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  use UV;

  # A new handle will be initialized against the default loop
  my $async = UV::Async->new();

  # Use a different loop
  my $loop = UV::Loop->new(); # non-default loop
  my $async = UV::Async->new(
    loop => $loop,
    on_close => sub {say "close!"},
    on_async => sub {say "async!"},
  );

  # setup the async callback:
  $async->on(async => sub {say "We're IDLING!!!"});

  # trigger the async callback
  $async->send();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's async|http://docs.libuv.org/en/v1.x/async.html> handle.

Async handles store a callback to be invoked when requested by some
possibly-asynchronous activity, such as in a signal handler or OS-level
thread. They are generally not that useful from Perl code, but are included
for completeness in case a situation arises for them.

=head1 EVENTS

L<UV::Async> inherits all events from L<UV::Handle> and also makes the
following extra events available.

=head2 async

    $handle->on(async => sub { my $invocant = shift; say "We were invoked!"});
    my $count = 0;
    $handle->on("async", sub {
        my $invocant = shift; # the handle instance this event fired on
        if (++$count > 2) {
            say "We were invoked twice. stopping!";
            $invocant->stop();
        }
    });

When the event loop runs and the async is invoked, this event will be fired.

=head1 METHODS

L<UV::Async> inherits all methods from L<UV::Handle> and also makes the
following extra methods available.

=head2 new

    my $async = UV::Async->new();
    # Or tell it what loop to initialize against
    my $async = UV::Async->new(
        loop => $loop,
        on_close => sub {say "close!"},
        on_async => sub {say "async!"},
    );

This constructor method creates a new L<UV::Async> object and
L<initializes|http://docs.libuv.org/en/v1.x/async.html#c.uv_async_init> the
handle with the given L<UV::Loop>. If no L<UV::Loop> is provided, then the
L<UV::Loop/"default_loop"> is assumed.

=head2 send

    $async->send();

The L<send|http://docs.libuv.org/en/v1.x/async.html#c.uv_async_send> method
schedules the event loop to wake up and invoke the async callback.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
