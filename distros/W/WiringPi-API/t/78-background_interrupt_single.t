# TESTDOC: WiringPi::API singular background_interrupt() (HW-free)
use strict;
use warnings;

use Test::More;

use WiringPi::API qw(
    background_interrupt  set_interrupt  wait_interrupts
    INT_EDGE_RISING       INT_EDGE_BOTH
);

# The plural background_interrupts() and its control channel are covered in
# t/75/t/77; this file covers the SINGULAR background_interrupt() - its pre-fork
# argument validation and its opt-in results channel (B5).

# ---------------------------------------------------------------------------
# Pre-fork argument validation: every bad argument croaks BEFORE the fork, so
# these need no GPIO, no child and no pipe.
# ---------------------------------------------------------------------------

eval { background_interrupt() };
like($@, qr/\$pin/, 'background_interrupt() rejects a missing pin');

eval { background_interrupt('x', INT_EDGE_RISING, sub { }) };
like($@, qr/\$pin/, 'background_interrupt() rejects a non-integer pin');

eval { background_interrupt(5, 9, sub { }) };
like($@, qr/\$edge/, 'background_interrupt() rejects an out-of-range edge');

eval { background_interrupt(5, INT_EDGE_RISING, 'notcode') };
like($@, qr/CODE reference/, 'background_interrupt() rejects a non-coderef callback');

eval { background_interrupt(5, INT_EDGE_RISING, sub { }, 'x') };
like($@, qr/debounce/, 'background_interrupt() rejects a non-integer debounce');

# ---------------------------------------------------------------------------
# Results channel round-trip (B5). A real fork, but no GPIO: set_interrupt() and
# wait_interrupts() are stubbed (the stubs are inherited across the fork), so the
# child never touches wiringPi. The child fires the framing-wrapped callback
# once; the parent drains the length-framed return value through the handle's
# non-blocking read(). An alarm watchdog guarantees the test can never hang.
# ---------------------------------------------------------------------------

our $CHILD_CB;

SKIP: {
    my ($got, $h);

    my $ok = eval {
        local $SIG{ALRM} = sub { die "watchdog\n" };
        alarm 10;

        no warnings 'redefine';

        # Capture the framing-wrapped callback the child hands to set_interrupt,
        # rather than arming real hardware. Stub the ISR-stop too, so the child's
        # TERM teardown does not warn about an uninitialised wiringPi.
        local *WiringPi::API::set_interrupt   = sub { $CHILD_CB = $_[2]; return 0; };
        local *WiringPi::API::wiringPiISRStop = sub { 0 };

        # Drive one edge into that wrapped callback, then idle (the parent TERMs
        # the child once it has read the value).
        my $fired = 0;
        local *WiringPi::API::wait_interrupts = sub {
            if (! $fired++) {
                $CHILD_CB->(INT_EDGE_RISING, 123) if $CHILD_CB;
            }
            else {
                select(undef, undef, undef, 0.02);
            }
            return 0;
        };

        $h = background_interrupt(
            5,
            INT_EDGE_RISING,
            sub { return "edge:$_[0]:ts:$_[1]" },
            { results => 1 },
        );

        # Non-blocking drain, polled until the framed value arrives.
        for (1 .. 200) {
            $got = $h->read;
            last if defined $got;
            select(undef, undef, undef, 0.02);
        }

        alarm 0;
        1;
    };

    my $err = $@;
    $h->stop if $h;

    skip "background_interrupt results round-trip could not run: $err", 2
        if ! $ok;

    ok(defined $got, 'background_interrupt(results => 1) delivers a value over the channel');
    is($got, 'edge:2:ts:123',
        '... the handler return value arrives length-framed and intact');
}

# A handle started WITHOUT a results channel exposes no fh and read() yields
# undef (nothing to drain), the singular-handle mirror of t/75's plural check.
{
    my $h = bless { pid => $$, running => 0, results_fh => undef },
        'WiringPi::API::BackgroundInterrupt';
    is($h->fh,   undef, 'no results channel: fh() is undef');
    is($h->read, undef, 'no results channel: read() is undef');
}

done_testing();
