use strict;
use warnings;

use POSIX ();
use Test::More;

use WiringPi::API ();
use WiringPi::API::BackgroundInterrupts;

# F4 coverage: arm()/disarm() must refresh child liveness before writing and
# survive a write to a dead child (EPIPE) instead of raising SIGPIPE or
# silently losing the command. The handle is built directly via _new (as t/75
# does) - the control-pipe protocol needs no GPIO.

# ---------------------------------------------------------------------------
# Live child: commands are delivered and acknowledged with a true return
# ---------------------------------------------------------------------------

{
    pipe(my $cr, my $cw) or die "pipe: $!";   # Control: parent -> child
    pipe(my $rr, my $rw) or die "pipe: $!";   # Echo: child -> parent

    my $pid = fork // die "fork: $!";
    if (! $pid) {
        close $cw;
        close $rr;
        while (my $line = <$cr>) {            # Echo each control line back
            syswrite $rw, $line;
        }
        POSIX::_exit(0);
    }
    close $cr;
    close $rw;

    my $h = WiringPi::API::BackgroundInterrupts->_new($pid, $cw, [5, 9]);

    is($h->arm(5), 1, 'arm() returns 1 with a live child');
    is(scalar <$rr>, "arm 5\n", '... and the arm command was delivered');

    is($h->disarm(9), 1, 'disarm() returns 1 with a live child');
    is(scalar <$rr>, "disarm 9\n", '... and the disarm command was delivered');

    eval { $h->arm(6) };
    like($@, qr/registered/, 'arm() still croaks on an unregistered pin');

    eval { $h->disarm(6) };
    like($@, qr/registered/, 'disarm() still croaks on an unregistered pin');

    ok($h->stop, 'stop() tears the child down');
    is($h->running, 0, '... and the child is gone');
}

# ---------------------------------------------------------------------------
# EPIPE: the child is alive (running() is true) but has closed its read end,
# so the syswrite itself fails. Pre-fix this killed the process with SIGPIPE.
# ---------------------------------------------------------------------------

{
    pipe(my $cr, my $cw) or die "pipe: $!";
    pipe(my $sync_r, my $sync_w) or die "pipe: $!";

    my $pid = fork // die "fork: $!";
    if (! $pid) {
        close $cw;
        close $sync_r;
        close $cr;                  # Drop the read end -> parent write EPIPEs
        syswrite $sync_w, 'x';      # Signal: read end is closed
        sleep 30;                   # Stay alive so running() stays true
        POSIX::_exit(0);
    }
    close $cr;
    close $sync_w;
    sysread $sync_r, my $ready, 1;  # Wait for the child to close its read end

    my $h = WiringPi::API::BackgroundInterrupts->_new($pid, $cw, [5]);

    is($h->running, 1, 'child is alive before the failed write');
    is($h->arm(5), 0, 'arm() returns 0 on EPIPE instead of dying of SIGPIPE');
    is($h->disarm(5), 0, 'disarm() returns 0 on EPIPE too');
    ok(! defined $SIG{PIPE}, 'the SIGPIPE handler was only localized');
    is($h->running, 1, 'the failed write did not falsely mark the child dead');

    ok($h->stop, 'stop() reaps the sleeping child');
}

# ---------------------------------------------------------------------------
# Dead child: once the child has exited, arm() must refuse - running()'s
# WNOHANG reap fires before any write is attempted
# ---------------------------------------------------------------------------

{
    pipe(my $cr, my $cw) or die "pipe: $!";

    my $pid = fork // die "fork: $!";
    if (! $pid) {
        POSIX::_exit(0);            # Die immediately
    }
    close $cr;

    my $h = WiringPi::API::BackgroundInterrupts->_new($pid, $cw, [5]);

    # Until the exit lands a write can still succeed (the kernel buffers it),
    # so poll: the moment the child is gone, arm() must return 0
    my $rv = 1;
    for (1 .. 200) {
        $rv = $h->arm(5);
        last if ! $rv;
        select(undef, undef, undef, 0.01);
    }

    is($rv, 0, 'arm() returns 0 once the child is dead');
    is($h->running, 0, 'running() reaped the dead child');
    is($h->disarm(5), 0, 'disarm() refuses on the dead child too');
}

done_testing();
