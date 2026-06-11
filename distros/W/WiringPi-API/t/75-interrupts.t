use strict;
use warnings;

use Test::More;
use POSIX ();
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use Time::HiRes qw(usleep time);

use WiringPi::API qw(
    setup           setup_gpio          pin_mode            pull_up_down
    set_interrupt   dispatch_interrupts wait_interrupts
    stop_interrupt  stop_interrupts     interrupt_fd        interrupt_dropped
    last_interrupt  interrupt_buffer    background_interrupts
    run_interrupt_loop                  stop_interrupt_loop
    auto_dispatch_interrupts
    INT_EDGE_SETUP  INT_EDGE_FALLING    INT_EDGE_RISING     INT_EDGE_BOTH
);

# The wiringPi ISR thread writes a fixed record to the self-pipe (isr_event_t in
# API.xs): {int pin; unsigned int pin_bcm; int edge; int status; long long ts}.
# Perl unpacks it as "i I i i q" (24 bytes).
use constant REC => 'i I i i q';

# ---------------------------------------------------------------------------
# Hardware-free: edge constants
# ---------------------------------------------------------------------------

is(INT_EDGE_SETUP,   0, 'INT_EDGE_SETUP == 0');
is(INT_EDGE_FALLING, 1, 'INT_EDGE_FALLING == 1');
is(INT_EDGE_RISING,  2, 'INT_EDGE_RISING == 2');
is(INT_EDGE_BOTH,    3, 'INT_EDGE_BOTH == 3');

# ---------------------------------------------------------------------------
# Hardware-free: set_interrupt() argument validation. These croak before any
# hardware call, so they need no Pi.
# ---------------------------------------------------------------------------

eval { set_interrupt("x", INT_EDGE_RISING, sub {}) };
like($@, qr/\$pin/, 'set_interrupt rejects a non-integer pin');

eval { set_interrupt(5, INT_EDGE_SETUP, sub {}) };
like($@, qr/\$edge/, 'set_interrupt rejects INT_EDGE_SETUP (0) - not a trigger');

eval { set_interrupt(5, 9, sub {}) };
like($@, qr/\$edge/, 'set_interrupt rejects an out-of-range edge');

eval { set_interrupt(5, INT_EDGE_RISING, "notcode") };
like($@, qr/CODE/, 'set_interrupt rejects a non-coderef callback');

eval { set_interrupt(5, INT_EDGE_RISING, sub {}, "x") };
like($@, qr/debounce/, 'set_interrupt rejects a non-integer debounce');

# ---------------------------------------------------------------------------
# Hardware-free: dispatch routing + teardown. Fake the self-pipe boundary
# (interrupt_fd + the two C calls) so dispatch_interrupts() can be exercised
# with hand-written records and no GPIO.
# ---------------------------------------------------------------------------

{
    pipe(my $rx, my $tx) or die "pipe: $!";
    my $flags = fcntl($rx, F_GETFL, 0);
    fcntl($rx, F_SETFL, $flags | O_NONBLOCK);   # mirror the real non-blocking read end

    no warnings 'redefine';
    local *WiringPi::API::interrupt_fd    = sub { fileno($rx) };
    local *WiringPi::API::_arm_interrupt  = sub { 0 };          # skip GPIO
    local *WiringPi::API::wiringPiISRStop = sub { 0 };          # skip GPIO

    my @got;
    set_interrupt(7, INT_EDGE_RISING,  sub { push @got, "7:$_[0]:$_[1]" });
    set_interrupt(9, INT_EDGE_FALLING, sub { push @got, "9:$_[0]:$_[1]" });

    # Records carry {pin, pin_bcm, edge, status, ts}; pin 7 = BCM 17, pin 9 = BCM 27.
    syswrite($tx, pack REC, 7, 17, 2, 1, 111);
    syswrite($tx, pack REC, 9, 27, 1, 1, 222);
    syswrite($tx, pack REC, 7, 17, 2, 1, 333);

    is(dispatch_interrupts(), 3, 'dispatch_interrupts() drains all 3 pending records');
    is_deeply(\@got, ['7:2:111', '9:1:222', '7:2:333'],
        'records route to the right per-pin callback with (edge, ts)');

    # last_interrupt() reflects the most recent dispatched record, full wfiStatus
    is_deeply(last_interrupt(),
        { pin => 7, pin_bcm => 17, edge => 2, status => 1, ts_us => 333 },
        'last_interrupt() reports the most recent event with the full wfiStatus');

    is(dispatch_interrupts(), 0, 'a second drain returns 0 (no busy-spin when empty)');

    # stop_interrupt removes one pin only
    @got = ();
    stop_interrupt(7);
    syswrite($tx, pack REC, 7, 17, 2, 1, 444);
    syswrite($tx, pack REC, 9, 27, 1, 1, 555);
    dispatch_interrupts();
    is_deeply(\@got, ['9:1:555'], 'stop_interrupt($pin) forgets only that pin');

    # stop_interrupts clears the rest
    @got = ();
    stop_interrupts();
    is(last_interrupt(), undef, 'last_interrupt() is undef after stop_interrupts()');
    set_interrupt(9, INT_EDGE_FALLING, sub { push @got, "again" }) if 0;  # do not re-register
    syswrite($tx, pack REC, 9, 27, 1, 1, 666);
    dispatch_interrupts();
    is_deeply(\@got, [], 'stop_interrupts() clears the whole registry');
}

# interrupt_dropped() accessor is callable and returns a number
like(interrupt_dropped(), qr/^\d+$/, 'interrupt_dropped() returns a count');

# ---------------------------------------------------------------------------
# Hardware-free: interrupt_buffer() get/set + validation. Fake the pipe so the
# F_GETPIPE_SZ/F_SETPIPE_SZ path runs against a real kernel pipe, no GPIO.
# ---------------------------------------------------------------------------

{
    pipe(my $rx, my $tx) or die "pipe: $!";

    no warnings 'redefine';
    local *WiringPi::API::interrupt_fd = sub { fileno($rx) };

    like(interrupt_buffer(), qr/^\d+$/,
        'interrupt_buffer() getter returns the current pipe size');

    my $want = 64 * 1024;
    my $got  = interrupt_buffer($want);
    cmp_ok($got, '>=', $want,
        'interrupt_buffer($bytes) sets the capacity (kernel grants >= request)');
    is(interrupt_buffer(), $got, 'getter reflects the size just set');

    eval { interrupt_buffer(0) };
    like($@, qr/positive integer/, 'interrupt_buffer(0) is rejected');

    eval { interrupt_buffer("big") };
    like($@, qr/positive integer/, 'interrupt_buffer(non-integer) is rejected');

    stop_interrupts();   # drop the cached read handle before the next fake pipe
}

# ---------------------------------------------------------------------------
# Hardware-free: run_interrupt_loop()/stop_interrupt_loop(). Fake the pipe so
# the loop dispatches injected records, no GPIO.
# ---------------------------------------------------------------------------

{
    pipe(my $rx, my $tx) or die "pipe: $!";
    my $flags = fcntl($rx, F_GETFL, 0);
    fcntl($rx, F_SETFL, $flags | O_NONBLOCK);

    no warnings 'redefine';
    local *WiringPi::API::interrupt_fd    = sub { fileno($rx) };
    local *WiringPi::API::_arm_interrupt  = sub { 0 };
    local *WiringPi::API::wiringPiISRStop = sub { 0 };

    stop_interrupts();   # ensure no stale cached read handle from a prior block

    # $max stops the loop after N dispatched events
    my @seen;
    set_interrupt(3, INT_EDGE_RISING, sub { push @seen, $_[0] });
    syswrite($tx, pack REC, 3, 17, 2, 1, 10);
    syswrite($tx, pack REC, 3, 17, 2, 1, 20);
    is(run_interrupt_loop(50, 2), 2,
        'run_interrupt_loop($timeout, $max) returns after $max events');
    is(scalar(@seen), 2, 'the loop dispatched exactly $max events to the callback');

    # stop_interrupt_loop() called from a callback breaks the loop
    @seen = ();
    set_interrupt(3, INT_EDGE_RISING, sub { push @seen, $_[0]; stop_interrupt_loop() });
    syswrite($tx, pack REC, 3, 17, 2, 1, 30);
    is(run_interrupt_loop(50), 1,
        'stop_interrupt_loop() in a callback breaks run_interrupt_loop()');

    stop_interrupts();
}

eval { run_interrupt_loop(0) };
like($@, qr/positive integer/, 'run_interrupt_loop() rejects a zero timeout');

eval { run_interrupt_loop(100, 0) };
like($@, qr/positive integer/, 'run_interrupt_loop() rejects a zero $max');

# background_interrupts() spec validation - all croak before forking, no GPIO
eval { background_interrupts() };
like($@, qr/at least one/, 'background_interrupts() with no specs is rejected');

eval { background_interrupts("notaref") };
like($@, qr/array reference/, 'background_interrupts() rejects a non-arrayref spec');

eval { background_interrupts([5, INT_EDGE_RISING, "notcode"]) };
like($@, qr/CODE reference/, 'background_interrupts() rejects a non-coderef in a spec');

eval { background_interrupts([5, 9, sub {}]) };
like($@, qr/\$edge/, 'background_interrupts() rejects a bad edge in a spec');

# The shared-child handle has no results channel: the inherited read/fh must
# reject rather than silently return undef. Build the handle directly (no fork,
# no GPIO) and clear running so DESTROY can't signal this test process.
{
    my $h = WiringPi::API::BackgroundInterrupts->_new($$, undef, [5]);
    $h->{running} = 0;

    eval { $h->read };
    like($@, qr/no results channel/, 'background_interrupts() handle read() rejects');

    eval { $h->fh };
    like($@, qr/no results channel/, 'background_interrupts() handle fh() rejects');
}

# auto_dispatch_interrupts() validation + signal selection (no pipe required:
# the fd wiring no-ops with no interrupt armed, so this stays hardware-free).
eval { auto_dispatch_interrupts() };
like($@, qr/boolean/, 'auto_dispatch_interrupts() requires a boolean');

eval { auto_dispatch_interrupts(1, 'NOPE') };
like($@, qr/unknown signal/, 'auto_dispatch_interrupts() rejects an unknown signal');

{
    is(auto_dispatch_interrupts(1, 'USR2'), 1, 'auto_dispatch_interrupts(1, USR2) enables');
    ok(defined $SIG{USR2}, '... installs a handler on the chosen signal');
    ok(! defined $SIG{IO}, '... leaving SIGIO untouched');
    is(auto_dispatch_interrupts(0), 1, 'auto_dispatch_interrupts(0) disables');
    ok(! defined $SIG{USR2}, '... and restores the chosen signal handler');
}

# ---------------------------------------------------------------------------
# Real hardware (opt-in via PI_BOARD). Uses BCM17 driven by toggling its
# internal pull resistor - electrically safe (a weak pull can't damage a wired
# device and can't override an external driver) and produces real edges on a
# floating pin. Each setup mode runs in its own forked child so wiringPi's
# once-per-process setup stays isolated.
# ---------------------------------------------------------------------------

SKIP: {
    skip "set PI_BOARD=1 (and wire nothing to BCM17) to run the GPIO interrupt tests", 7
        unless $ENV{PI_BOARD};

    # setup_gpio() / BCM numbering: arm BCM17, re-arm, drive 5 pull cycles,
    # then tear down.
    my %g = _kv(run_child(sub {
        setup_gpio();
        pin_mode(17, 0);
        pull_up_down(17, 2); usleep(50_000);

        my $fd_before = interrupt_fd();
        my @e;
        set_interrupt(17, INT_EDGE_BOTH, sub { push @e, $_[0] });
        set_interrupt(17, INT_EDGE_BOTH, sub { push @e, $_[0] });   # re-arm: must not stack
        my $fd_armed = interrupt_fd();

        for (1 .. 5) {
            pull_up_down(17, 1); usleep(30_000); dispatch_interrupts();
            pull_up_down(17, 2); usleep(30_000); dispatch_interrupts();
        }
        my $seq = "@e";

        stop_interrupt(17);
        @e = ();
        pull_up_down(17, 1); usleep(30_000);
        pull_up_down(17, 2); usleep(30_000); dispatch_interrupts();
        my $after_stop = scalar @e;

        stop_interrupts();
        return "fd_before=$fd_before;fd_armed=$fd_armed;seq=$seq;"
             . "after_stop=$after_stop;fd_end=" . interrupt_fd();
    }));

    is($g{fd_before}, -1,        'interrupt_fd() is -1 before arming');
    cmp_ok($g{fd_armed}, '>=', 0, 'interrupt_fd() is a real fd after arming');
    is($g{seq}, '1 2 1 2 1 2 1 2 1 2',
        'setup_gpio: 5 pull cycles -> 10 edges in FALLING/RISING order (re-arm did not double)');
    is($g{after_stop}, 0,        'no edges fire after stop_interrupt()');
    is($g{fd_end}, -1,           'interrupt_fd() is -1 again after stop_interrupts()');

    # setup() / wiringPi numbering: wpi pin 0 == BCM17. Proves the callback is
    # keyed by the user's pin (via userdata), not wfiStatus.pinBCM.
    my %w = _kv(run_child(sub {
        setup();
        pin_mode(0, 0);
        pull_up_down(0, 2); usleep(50_000);
        my @e;
        set_interrupt(0, INT_EDGE_BOTH, sub { push @e, $_[0] });
        for (1 .. 5) {
            pull_up_down(0, 1); usleep(30_000); dispatch_interrupts();
            pull_up_down(0, 2); usleep(30_000); dispatch_interrupts();
        }
        stop_interrupts();
        return "seq=@e";
    }));
    is($w{seq}, '1 2 1 2 1 2 1 2 1 2',
        'setup(): wpi-pin-0 callback fires (userdata keying, not pinBCM)');

    # Background via fork: a child arms + dispatches while the parent drives.
    my %b = _kv(run_child(sub {
        setup_gpio();
        pin_mode(17, 0);
        pull_up_down(17, 2); usleep(50_000);

        pipe(my $r, my $w) or die "pipe: $!";
        my $kid = fork // die "fork: $!";
        if (! $kid) {                       # grandchild: background dispatcher
            close $r;
            set_interrupt(17, INT_EDGE_BOTH, sub { syswrite $w, "e" });
            my $end = time + 2;
            while (time < $end) { wait_interrupts(200) }
            stop_interrupts();
            close $w;
            POSIX::_exit(0);
        }
        close $w;
        usleep(150_000);
        for (1 .. 5) {                      # parent drives, concurrently
            pull_up_down(17, 1); usleep(60_000);
            pull_up_down(17, 2); usleep(60_000);
        }
        local $/; my $rep = <$r>;
        waitpid $kid, 0;
        return "count=" . (($rep // '') =~ tr/e/e/);
    }));
    is($b{count}, 10, 'fork: a background child dispatches edges the parent drives');
}

done_testing();

# Run $code in a forked child; return whatever it prints/returns as a string.
# _exit avoids the child running Test::More's END (which would emit a plan).
sub run_child {
    my $code = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    my $pid = fork;
    defined $pid or die "fork: $!";
    if (! $pid) {
        close $r;
        my $out = eval { $code->() };
        $out = "DIE:$@" if ! defined $out;
        syswrite $w, $out;
        close $w;
        POSIX::_exit(0);
    }
    close $w;
    local $/;
    my $out = <$r>;
    waitpid $pid, 0;
    return $out // '';
}

sub _kv {
    my $s = shift // '';
    return map { split /=/, $_, 2 } split /;/, $s;
}
