use strict;
use warnings;

use Test::More;
use Time::HiRes qw(usleep);

use WiringPi::API qw(
    worker      pi_lock     pi_unlock
    setup_gpio  pin_mode    read_pin    write_pin
);

# worker() runs arbitrary Perl in a forked child. Every case above the final
# block touches no hardware and runs off-Pi; the RPI_BOARD-gated block at the end
# drives a real pin through a worker.

# ---------------------------------------------------------------------------
# Argument validation: everything croaks BEFORE any fork.
# ---------------------------------------------------------------------------

eval { worker() };
like($@, qr/CODE reference/, 'worker() with no body croaks');

eval { worker("notcode") };
like($@, qr/CODE reference/, 'worker() with a non-CODE body croaks');

eval { worker(sub { 1 }, "notahash") };
like($@, qr/hash reference/, 'worker() with non-HASH opts croaks');

eval { worker(sub { 1 }, { interval => "soon" }) };
like($@, qr/interval/, 'worker() with non-numeric interval croaks');

eval { worker(sub { 1 }, { interval => 0 }) };
like($@, qr/interval/, 'worker() with zero interval croaks');

eval { worker(sub { 1 }, { interval => -2 }) };
like($@, qr/interval/, 'worker() with negative interval croaks');

eval { worker(sub { 1 }, { mechanism => 'bogus' }) };
like($@, qr/'fork' or 'thread'/, 'worker() with unknown mechanism croaks');

# This Perl may or may not be threaded; either way, asking for thread mode
# without 'use threads' must croak with a clear, actionable message.
SKIP: {
    skip "threads is loaded", 1 if $INC{'threads.pm'};
    eval { worker(sub { 1 }, { mechanism => 'thread' }) };
    like($@, qr/requires threads to be loaded/,
        'worker({mechanism=>thread}) croaks when threads not loaded');
}

# ---------------------------------------------------------------------------
# pi_lock() / pi_unlock(): validate the lock key (0..3) before the XS call.
# ---------------------------------------------------------------------------

eval { pi_lock(9) };
like($@, qr/0, 1, 2 or 3/, 'pi_lock() rejects an out-of-range key');

eval { pi_lock() };
like($@, qr/0, 1, 2 or 3/, 'pi_lock() rejects a missing key');

eval { pi_unlock(-1) };
like($@, qr/0, 1, 2 or 3/, 'pi_unlock() rejects an out-of-range key');

eval { pi_unlock("x") };
like($@, qr/0, 1, 2 or 3/, 'pi_unlock() rejects a non-numeric key');

# ---------------------------------------------------------------------------
# Construction + lifecycle: pid / running / idempotent stop.
# ---------------------------------------------------------------------------

{
    my $w = worker(sub { usleep 20_000 });
    isa_ok($w, 'WiringPi::API::Worker', 'handle');
    ok($w->pid > 0,  'pid() is a real pid');
    ok($w->running,  'running() true while alive');

    ok($w->stop,     'stop() returns true');
    ok($w->stop,     'stop() is idempotent');
    ok(! $w->running, 'running() false after stop');
}

# ---------------------------------------------------------------------------
# Reaping: an explicitly stopped child leaves no zombie.
# ---------------------------------------------------------------------------

{
    my $w   = worker(sub { usleep 20_000 });
    my $pid = $w->pid;
    $w->stop;
    is(waitpid($pid, 1), -1, 'stopped child already reaped (no zombie)');  # WNOHANG
}

# ---------------------------------------------------------------------------
# {results => 1}: every defined return value streams back, length-framed.
# ---------------------------------------------------------------------------

{
    my $i = 0;
    my $w = worker(
        sub { my $n = $i++; usleep 5_000; return $n; },
        { results => 1 },
    );

    isa_ok($w->fh, 'GLOB', 'results fh()');

    my @got;
    for (1 .. 50) {
        last if @got >= 5;
        my $v = $w->read;
        if (defined $v) {
            push @got, $v;
            next;
        }
        usleep 5_000;
    }
    $w->stop;

    ok(@got >= 3, 'results channel streamed several values') or diag "got: @got";
    is_deeply([@got[0 .. 2]], [0, 1, 2], 'streamed values arrive in order');
}

# ---------------------------------------------------------------------------
# {shared => 1}: value() returns the latest value (lossy), and caches it.
# ---------------------------------------------------------------------------

{
    my $i = 0;
    my $w = worker(
        sub { my $n = $i++; usleep 5_000; return $n; },
        { shared => 1 },
    );

    # Let the child publish a handful of updates, then stop it so no further
    # writes can race the assertions below.
    usleep 60_000;
    $w->stop;

    my $latest = $w->value;     # drains everything pending, caches the last
    ok(defined $latest, 'value() returned a latest value');
    ok($latest > 0, 'value() advanced past the first update (lossy latest)')
        or diag "latest: $latest";

    # With nothing new pending, value() returns the cached latest.
    is($w->value, $latest, 'value() caches the last seen value');
}

# ---------------------------------------------------------------------------
# value() / read() are undef when their channel was not requested.
# ---------------------------------------------------------------------------

{
    my $w = worker(sub { usleep 20_000 });
    is($w->value, undef, 'value() is undef without {shared}');
    is($w->read,  undef, 'read() is undef without {results}');
    is($w->fh,    undef, 'fh() is undef without {results}');
    $w->stop;
}

# ---------------------------------------------------------------------------
# WorkerThread contract: thread mode has no pipe channels, so read()/fh()/value()
# croak (consistent with BackgroundInterrupts) instead of silently returning
# undef like a fork worker does. The croak is unconditional, so it is asserted
# here directly on the handle class - no ithread Perl required. The end-to-end
# thread-construction path is covered in t/86-worker_thread.t.
# ---------------------------------------------------------------------------

{
    require WiringPi::API::WorkerThread;
    my $wt = bless {}, 'WiringPi::API::WorkerThread';
    my $re = qr/no pipe channels.*pi_lock/;

    eval { $wt->read };
    like($@, $re, 'WorkerThread read() croaks (no pipe channel under thread mode)');

    eval { $wt->fh };
    like($@, $re, 'WorkerThread fh() croaks (no pipe channel under thread mode)');

    eval { $wt->value };
    like($@, $re, 'WorkerThread value() croaks (no pipe channel under thread mode)');

    # croak must blame the caller's line (this file), not WorkerThread.pm.
    eval { $wt->read };
    like($@, qr/\bat \Q$0\E line \d+/, 'WorkerThread croak is reported from the caller');
}

# ---------------------------------------------------------------------------
# {once => 1}: body runs exactly once, then the child exits on its own.
# ---------------------------------------------------------------------------

{
    my $i = 0;
    my $w = worker(
        sub { $i++; return $i; },
        { once => 1, results => 1 },
    );

    # The child exits after one pass; wait for running() to reflect that.
    my $exited;
    for (1 .. 200) {
        if (! $w->running) {
            $exited = 1;
            last;
        }
        usleep 5_000;
    }
    ok($exited, '{once} child exits on its own');
    ok(! $w->running, '{once} running() is false after the single pass');

    # Exactly one value was produced.
    my @got;
    while (defined(my $v = $w->read)) {
        push @got, $v;
    }
    is_deeply(\@got, [1], '{once} body ran exactly once');

    $w->stop;   # idempotent on an already-exited child
}

# ---------------------------------------------------------------------------
# {interval => $secs}: the helper paces the loop; the body carries no sleep.
# ---------------------------------------------------------------------------

{
    my $i = 0;
    my $w = worker(
        sub { my $n = $i++; return $n; },
        { interval => 0.05, results => 1 },
    );

    # Over ~0.5s at a 50ms cadence we expect roughly 10 passes - assert a loose
    # window so the test is timing-tolerant but still proves pacing happened
    # (without pacing, an empty body would spin thousands of times).
    usleep 500_000;
    $w->stop;

    my @got;
    while (defined(my $v = $w->read)) {
        push @got, $v;
    }

    ok(@got >= 3,  'interval worker produced several passes') or diag "n=" . @got;
    ok(@got <= 40, 'interval paced the loop (not a busy spin)') or diag "n=" . @got;
    is_deeply([@got[0 .. 2]], [0, 1, 2], 'interval passes arrive in order');
}

# ---------------------------------------------------------------------------
# Real hardware (opt-in via RPI_BOARD). Uses BCM17 as an OUTPUT and proves the
# hands-off contract across the fork boundary: the parent does setup once, the
# forked worker inherits the mapped GPIO and drives/reads the pin. Driving an
# unwired output pin is electrically safe, so nothing need be connected.
# ---------------------------------------------------------------------------

SKIP: {
    skip "set RPI_BOARD=1 (and wire nothing to BCM17) to run the GPIO worker tests", 5
        unless $ENV{RPI_BOARD};

    setup_gpio();           # BCM numbering, once in the parent
    pin_mode(17, 1);        # OUTPUT - inherited by the forked worker

    # A worker owns the loop and toggles the pin; the parent (sharing the same
    # GPIO hardware) polls read_pin and must observe both levels. stop() then
    # leaves no zombie.
    {
        my $w = worker(
            sub { write_pin(17, 1); usleep 20_000; write_pin(17, 0); usleep 20_000 },
        );

        my %seen;
        for (1 .. 400) {
            $seen{ read_pin(17) } = 1;
            last if $seen{0} && $seen{1};
            usleep 5_000;
        }

        my $pid = $w->pid;
        $w->stop;

        ok($seen{1}, 'worker drove the pin HIGH (parent saw it)');
        ok($seen{0}, 'worker drove the pin LOW (parent saw it)');
        is(waitpid($pid, 1), -1, 'stopped GPIO worker left no zombie');  # WNOHANG
    }

    # {shared=>1} sampler: the worker reads the pin and publishes the latest
    # level; the parent drives the pin and reads it back through value(). Proves
    # the shared channel carries real GPIO state, not just synthetic returns.
    {
        write_pin(17, 1);
        my $s = worker(
            sub { return read_pin(17); },
            { shared => 1, interval => 0.02 },
        );

        my $high;
        for (1 .. 100) {
            usleep 10_000;
            $high = $s->value;
            last if defined $high && $high == 1;
        }

        write_pin(17, 0);

        my $low;
        for (1 .. 100) {
            usleep 10_000;
            $low = $s->value;
            last if defined $low && $low == 0;
        }

        $s->stop;

        is($high, 1, '{shared} sampler published the HIGH level via value()');
        is($low,  0, '{shared} sampler tracked the pin dropping to LOW');
    }

    write_pin(17, 0);       # Leave the pin low
}

done_testing();
