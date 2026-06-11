package WiringPi::API::WorkerThread;

use strict;
use warnings;

use WiringPi::API::Worker;

# Handle returned by worker() under {mechanism => 'thread'}. The thread
# lifecycle is nothing like a fork's (no pid, no signal/waitpid), so this
# subclass overrides pid/running/stop/DESTROY: stop() flips the shared flag and
# joins; running() reflects the thread and joins a self-finished ({once}) one.
# pid() reports the thread tid so the handle interface stays uniform.

our @ISA = ('WiringPi::API::Worker');

sub _new {
    my ($class, $thread, $stop_ref) = @_;

    return bless {
        thread   => $thread,
        stop_ref => $stop_ref,
        tid      => $thread->tid,
        running  => 1,
    }, $class;
}
sub pid {
    # Threads have no pid; report the tid so callers have a stable identifier.
    return $_[0]->{tid};
}
sub running {
    my ($self) = @_;

    return 0 if ! $self->{running};

    # A {once} thread exits on its own; join it so running() reflects reality.
    if ($self->{thread} && ! $self->{thread}->is_running) {
        $self->{thread}->join;
        $self->{thread}  = undef;
        $self->{running} = 0;
        return 0;
    }

    return 1;
}
sub stop {
    my ($self) = @_;

    return 1 if ! $self->{running};         # idempotent

    ${ $self->{stop_ref} } = 1;             # cooperative stop at next pass
    $self->{thread}->join if $self->{thread};
    $self->{thread}  = undef;
    $self->{running} = 0;

    return 1;
}
sub value {
    # No pipe channel under thread mode - shared-memory ergonomics replace it.
    return undef;
}

1;
__END__

=head1 NAME

WiringPi::API::WorkerThread - Handle for an ithread-based background worker

=head1 SYNOPSIS

    use threads;                      # required for mechanism => 'thread'
    use WiringPi::API qw(setup worker);

    setup();

    my $w = worker(sub {
        # ... body sharing state with main ...
        select(undef, undef, undef, 0.1);
    }, { mechanism => 'thread' });

    $w->stop;                         # sets the stop flag and joins the thread

=head1 DESCRIPTION

An object of this class is returned by L<WiringPi::API/worker(\&body, \%opts)>
under C<< mechanism => 'thread' >>, which runs the body in an ithread for
shared-memory ergonomics on a threaded Perl.

You never construct one directly - C<worker()> spawns the thread and hands you
the handle.

It is a subclass of L<WiringPi::API::Worker>, but the thread lifecycle is
nothing like a fork's (no pid, no signal/C<waitpid>), so this class overrides
C<pid>/C<running>/C<stop>/C<value>. There are no pipe channels under thread
mode - share a variable and serialise access with
L<WiringPi::API/pi_lock($key)> / L<WiringPi::API/pi_unlock($key)> instead.

=head1 METHODS

=head2 pid

Threads have no process id, so this reports the thread id (tid) instead, keeping
the handle interface uniform with the fork-based handles.

=head2 running

True while the thread is still alive; false once it has stopped. A
C<< once => 1 >> thread exits on its own, and C<running> joins such a
self-finished thread so it reflects reality.

=head2 stop

Set the cooperative stop flag (honoured at the next pass of the body) and join
the thread. Idempotent. Returns C<1>.

=head2 value

Always C<undef> under thread mode: there is no pipe channel, as shared-memory
ergonomics replace it.

=head1 SEE ALSO

L<WiringPi::API>, L<WiringPi::API::Worker>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
