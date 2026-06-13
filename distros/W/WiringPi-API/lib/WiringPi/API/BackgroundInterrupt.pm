package WiringPi::API::BackgroundInterrupt;

use strict;
use warnings;

use POSIX qw(WNOHANG ECHILD);

# Handle returned by background_interrupt(). Owns one forked child that arms the
# interrupt and runs the callback on each edge; stop() reaps it.

sub _new {
    my ($class, $pid, $results_fh) = @_;
    return bless { pid => $pid, running => 1, results_fh => $results_fh }, $class;
}
sub pid {
    return $_[0]->{pid};
}
sub fh {
    # The results read handle (for select/IO::Select), or undef if not enabled.
    return $_[0]->{results_fh};
}
sub read {
    # Non-blocking drain of the results channel: returns the next value the
    # handler reported, or undef if none is ready (or the channel is closed).
    my ($self) = @_;

    my $fh = $self->{results_fh};
    return undef if ! defined $fh;

    my $rin = "";
    vec($rin, fileno($fh), 1) = 1;
    my $nfound = select(my $rout = $rin, undef, undef, 0);
    return undef if ! $nfound || $nfound < 0;

    # One length-framed record is present. The single child writes each record
    # with one syswrite, so while the payload stays under PIPE_BUF (4096B, incl.
    # the 4-byte length frame) the write is atomic and the whole record is
    # buffered once the pipe is readable - _read_exact won't block. NOTE (B4): a
    # larger return value can be split across writes, and _read_exact would then
    # block waiting for the tail. Keep returned values under ~4KB for the
    # non-blocking guarantee (a non-blocking partial-buffer drain is a TODO).
    my $len_buf = _read_exact($fh, 4);
    return undef if ! defined $len_buf;

    return _read_exact($fh, unpack("N", $len_buf));
}
sub running {
    my ($self) = @_;

    return 0 if ! $self->{running};

    # Reap-if-exited so running() reflects reality without blocking. The child is
    # gone on a positive reap, or on -1/ECHILD (already reaped / no such child).
    # Any OTHER errno from waitpid - notably EINTR, where the call was interrupted
    # by a signal and says nothing about the child - is left alone, so a stray
    # signal can't latch a still-running handle as stopped (and leak the child).
    my $reaped = waitpid($self->{pid}, WNOHANG);
    if ($reaped == $self->{pid} || ($reaped == -1 && $! == ECHILD)) {
        $self->{running} = 0;
        return 0;
    }

    return 1;
}
sub stop {
    my ($self) = @_;

    return 1 if ! $self->{running};         # idempotent

    my $pid = $self->{pid};
    kill 'TERM', $pid;

    # poll briefly for a clean exit, then escalate
    for (1 .. 50) {
        my $reaped = waitpid($pid, WNOHANG);
        if ($reaped == $pid || $reaped == -1) {
            $self->{running} = 0;
            return 1;
        }
        select(undef, undef, undef, 0.01);  # 10ms
    }

    kill 'KILL', $pid;
    waitpid($pid, 0);
    $self->{running} = 0;

    return 1;
}
sub DESTROY {
    my ($self) = @_;
    $self->stop if $self->{running};
}

sub _read_exact {
    my ($fh, $n) = @_;

    my $buf = "";
    while (length($buf) < $n) {
        my $got = sysread($fh, my $chunk, $n - length($buf));
        return undef if ! defined $got || $got == 0;
        $buf .= $chunk;
    }

    return $buf;
}

1;
__END__

=head1 NAME

WiringPi::API::BackgroundInterrupt - Handle for a single-pin background
interrupt child

=head1 SYNOPSIS

    use WiringPi::API qw(setup pin_mode background_interrupt INT_EDGE_RISING);

    setup();
    pin_mode(17, 0);

    my $h = background_interrupt(17, INT_EDGE_RISING, \&on_edge);

    # ... main does its own work ...

    $h->stop;             # idempotent; END reaps if forgotten

=head1 DESCRIPTION

An object of this class is returned by
L<WiringPi::API/background_interrupt($pin, $edge, $callback, $debounce_us)>. It
owns one forked child that arms the interrupt and runs the callback on each
edge.

You never construct one directly - C<background_interrupt()> forks the child and
hands you the handle.

It is also the lifecycle base class for the other background-handle classes:
L<WiringPi::API::BackgroundInterrupts> (shared multi-pin child),
L<WiringPi::API::Worker> (fork-based worker) and, transitively,
L<WiringPi::API::WorkerThread>. The C<pid>/C<running>/C<stop>/C<DESTROY> fork
lifecycle (TERM -> poll -> KILL -> reap) is mechanism-agnostic, so those
subclasses inherit it wholesale.

=head1 METHODS

=head2 pid

The forked child's process id.

=head2 running

True while the child is still alive; false once it has stopped. Reaps the child
without blocking (via C<waitpid> C<WNOHANG>) so the result reflects reality.

=head2 stop

Stop the child and reap it: send C<TERM>, poll briefly for a clean exit, then
escalate to C<KILL>. B<Idempotent> - safe to call more than once, and C<DESTROY>
reaps the child if you forget. Returns C<1>.

=head2 read

Non-blocking drain of the results channel (when the child was started with
C<< results => 1 >>): returns the next value the handler reported, or C<undef>
if none is ready or the channel is closed/disabled.

=head2 fh

The results read handle, suitable for C<select>/L<IO::Select>, or C<undef> when
the results channel is not enabled.

=head1 SEE ALSO

L<WiringPi::API>, L<WiringPi::API::BackgroundInterrupts>,
L<WiringPi::API::Worker>, L<WiringPi::API::WorkerThread>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
