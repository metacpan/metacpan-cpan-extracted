package WiringPi::API::BackgroundInterrupts;

use strict;
use warnings;

use Carp qw(croak);
use WiringPi::API::BackgroundInterrupt;

# Handle for background_interrupts() - one shared child servicing many pins.
# Inherits pid/running/stop/DESTROY; adds arm/disarm over the control pipe.
# A shared child has no per-pin results channel (that is the singular
# background_interrupt({results => 1}) contract), so the inherited read/fh are
# overridden to reject rather than silently return undef.

our @ISA = ('WiringPi::API::BackgroundInterrupt');

sub _new {
    my ($class, $pid, $control_fh, $pins) = @_;

    my $self = $class->SUPER::_new($pid);
    $self->{control_fh} = $control_fh;
    $self->{pins}       = { map { $_ => 1 } @$pins };   # the registered set

    return $self;
}
sub arm {
    my ($self, $pin) = @_;

    if (! defined $pin || ! $self->{pins}{$pin}) {
        croak "arm(): pin must be one registered at background_interrupts() time";
    }

    return 0 if ! $self->{running};

    syswrite $self->{control_fh}, "arm $pin\n";
    return 1;
}
sub disarm {
    my ($self, $pin) = @_;

    if (! defined $pin || ! $self->{pins}{$pin}) {
        croak "disarm(): pin must be one registered at background_interrupts() time";
    }

    return 0 if ! $self->{running};

    syswrite $self->{control_fh}, "disarm $pin\n";
    return 1;
}
sub fh {
    croak "background_interrupts() has no results channel; use a per-pin " .
        "background_interrupt(\$pin, \$edge, \$cb, { results => 1 }) for results";
}
sub read {
    croak "background_interrupts() has no results channel; use a per-pin " .
        "background_interrupt(\$pin, \$edge, \$cb, { results => 1 }) for results";
}
sub stop {
    my ($self) = @_;

    # Closing the control pipe gives the child an EOF shutdown path; then the
    # inherited stop() does the TERM/KILL + reap.
    if ($self->{control_fh}) {
        close $self->{control_fh};
        $self->{control_fh} = undef;
    }

    return $self->SUPER::stop;
}

1;
__END__

=head1 NAME

WiringPi::API::BackgroundInterrupts - Handle for a shared multi-pin background
interrupt child

=head1 SYNOPSIS

    use WiringPi::API qw(setup pin_mode background_interrupts INT_EDGE_RISING
                         INT_EDGE_BOTH);

    setup();
    pin_mode(17, 0);
    pin_mode(27, 0);

    my $h = background_interrupts(
        [17, INT_EDGE_RISING, \&on_button],
        [27, INT_EDGE_BOTH,   \&on_sensor, 5000],
    );

    $h->disarm(27);   # stop servicing pin 27 (without killing the child)
    $h->arm(27);      # resume it
    $h->stop;         # tear down + reap the one child

=head1 DESCRIPTION

An object of this class is returned by
L<WiringPi::API/background_interrupts([$pin, $edge, $callback, $debounce_us], ...)>.
A B<single> forked child services B<many> pins from one dispatch loop, and this
handle drives it.

You never construct one directly - C<background_interrupts()> forks the child
and hands you the handle.

It is a subclass of L<WiringPi::API::BackgroundInterrupt> and inherits that
class's C<pid>, C<running> and C<DESTROY> lifecycle. A shared child has no
per-pin results channel (that is the singular C<< background_interrupt({results
=> 1}) >> contract), so the inherited C<read>/C<fh> are overridden to croak
rather than silently return C<undef>.

=head1 METHODS

=head2 arm($pin)

Resume servicing C<$pin>, which must be one of the pins registered in the
original C<background_interrupts()> call. Croaks otherwise. Returns C<0> if the
child is no longer running, C<1> once the arm command is sent.

=head2 disarm($pin)

Stop servicing C<$pin> (without killing the child), which must be one of the
pins registered in the original call. Croaks otherwise. Returns C<0> if the
child is no longer running, C<1> once the disarm command is sent.

=head2 stop

Close the control pipe (giving the child an EOF shutdown path), then stop and
reap the child via the inherited C<stop>. Idempotent. Returns C<1>.

=head2 fh / read

The shared child has no results channel, so both of these B<croak>. Use a
per-pin L<WiringPi::API/background_interrupt($pin, $edge, $callback,
$debounce_us)> with C<< { results => 1 } >> when you need values back from a
handler.

=head1 SEE ALSO

L<WiringPi::API>, L<WiringPi::API::BackgroundInterrupt>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
