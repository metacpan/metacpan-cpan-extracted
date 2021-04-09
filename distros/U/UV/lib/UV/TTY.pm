package UV::TTY;

our $VERSION = '1.907';

use strict;
use warnings;
use Carp ();
use parent 'UV::Stream';

sub _new_args {
    my ($class, $args) = @_;
    my $fd = delete $args->{fd} // delete $args->{single_arg};
    return ($class->SUPER::_new_args($args), $fd);
}

1;

__END__

=encoding utf8

=head1 NAME

UV::TTY - TTY stream handles in libuv

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;

  # A new stream handle will be initialised against the default loop
  my $tty = UV::TTY->new(fd => 0);

  # set up the data read callback
  $tty->on(read => sub {
    my ($self, $err, $buf) = @_;
    say "More data: $buf";
  });
  $tty->read_start();

=head1 DESCRIPTION

This module provides an interface to
L<libuv's TTY|http://docs.libuv.org/en/v1.x/tty.html> stream handle.

TTY handles represent a stream for the console.

=head1 EVENTS

L<UV::TTY> inherits all events from L<UV::Stream> and L<UV::Handle>.

=head1 METHODS

L<UV::TTY> inherits all methods from L<UV::Stream> and L<UV::Handle> and also
makes the following extra methods available.

=head2 set_mode

    $tty->set_mode($mode);

The L<set_mode|http://docs.libuv.org/en/v1.x/tty.html#c.uv_tty_set_mode>
method sets the mode of the TTY handle, to one of the C<UV_TTY_MODE_*>
constants.

=head2 get_winsize

    my ($width, $height) = $tty->get_winsize();

The L<get_winsize|http://docs.libuv.org/en/v1.x/tty.html#c.uv_tty_get_winsize>
method returns the size of the window.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
