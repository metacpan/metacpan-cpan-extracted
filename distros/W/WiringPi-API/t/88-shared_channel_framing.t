use strict;
use warnings;

use Test::More;
use Time::HiRes qw(usleep);
use POSIX qw(PIPE_BUF);

use WiringPi::API qw(worker);

# B10: the shared (value()) channel writer is non-blocking, so a length-framed
# record larger than PIPE_BUF could be written only partially and desync the
# reader into returning garbage. The writer now SKIPS oversized frames (the
# channel is lossy, so dropping a too-big update is consistent and keeps the
# stream aligned). The results (read()) channel uses a blocking write and is
# unaffected - it still delivers large values intact. Every case runs off-board
# (fork + pipe, no hardware).

my $UNDER = PIPE_BUF - 4;      # a payload this long frames to exactly PIPE_BUF

# Poll value()/read() so timing can't flake the assertions.
sub poll {
    my ($code) = @_;
    for (1 .. 60) {
        my $v = $code->();
        return $v if defined $v;
        usleep 5_000;
    }
    return undef;
}

# ---------------------------------------------------------------------------
# 1. Every shared value is oversized -> all dropped -> value() stays undef.
# ---------------------------------------------------------------------------
{
    my $big = 'X' x 8192;
    my $w = worker(sub { $big }, { shared => 1, interval => 0.01 });
    usleep 60_000;
    $w->stop;
    is($w->value, undef,
        'oversized shared values are all dropped (value() undef, no corruption)');
}

# ---------------------------------------------------------------------------
# 2. An in-size shared value still publishes (the guard does not over-drop).
# ---------------------------------------------------------------------------
{
    my $w = worker(sub { 'small' }, { shared => 1, interval => 0.01 });
    my $v = poll(sub { $w->value });
    $w->stop;
    is($v, 'small', 'in-size shared value publishes through value()');
}

# ---------------------------------------------------------------------------
# 3. Boundary: a frame of exactly PIPE_BUF (payload PIPE_BUF-4) is allowed.
# ---------------------------------------------------------------------------
{
    my $payload = 'a' x $UNDER;            # frame == PIPE_BUF -> atomic write
    my $w = worker(sub { $payload }, { shared => 1, interval => 0.01 });
    my $v = poll(sub { $w->value });
    $w->stop;
    ok(defined $v && $v eq $payload,
        "value framing to exactly PIPE_BUF is published (len " .
        (defined $v ? length $v : 'undef') . ")");
}

# ---------------------------------------------------------------------------
# 4. Boundary: a frame one byte over PIPE_BUF (payload PIPE_BUF-3) is dropped.
# ---------------------------------------------------------------------------
{
    my $payload = 'a' x (PIPE_BUF - 3);    # frame == PIPE_BUF + 1 -> dropped
    my $w = worker(sub { $payload }, { shared => 1, interval => 0.01 });
    usleep 60_000;
    $w->stop;
    is($w->value, undef,
        'value framing to PIPE_BUF + 1 is dropped (just over the limit)');
}

# ---------------------------------------------------------------------------
# 5. Oversized interleaved with a small sentinel: only the sentinel survives,
#    and value() returns it cleanly (never the big blob, never garbage).
# ---------------------------------------------------------------------------
{
    my $big = 'B' x 8192;
    my $n = 0;
    my $w = worker(sub { $n++ % 2 ? 'ok' : $big }, { shared => 1, interval => 0.01 });
    my $v = poll(sub { $w->value });
    $w->stop;
    is($v, 'ok',
        'shared value() returns the in-size sentinel; oversized frames never desync it');
}

# ---------------------------------------------------------------------------
# 6. Lossy-latest stays intact when oversized values are interleaved: value()
#    is always a clean small integer, never a corrupted/garbage read.
# ---------------------------------------------------------------------------
{
    my $big = 'B' x 9000;
    my $i = 0;
    my $w = worker(sub { $i++; $i % 2 ? $big : $i }, { shared => 1, interval => 0.01 });
    usleep 80_000;
    my $v = poll(sub { $w->value });
    $w->stop;
    ok(defined $v && $v =~ /^\d+$/ && length($v) < 10,
        "lossy-latest value() is a clean small integer amid oversized frames (got: " .
        (defined $v ? $v : 'undef') . ")");
}

# ---------------------------------------------------------------------------
# 7. Scope check: the results (read()) channel uses a blocking write, so a
#    large value is delivered INTACT (the guard is shared-only).
# ---------------------------------------------------------------------------
{
    my $big = 'R' x 8192;
    my $w = worker(sub { $big }, { results => 1, interval => 0.01 });
    my $got = poll(sub { $w->read });
    $w->stop;
    ok(defined $got && $got eq $big,
        "results read() delivers a > PIPE_BUF value intact (len " .
        (defined $got ? length $got : 'undef') . ")");
}

# ---------------------------------------------------------------------------
# 8. Both channels, large value: results delivers it intact; shared drops it.
# ---------------------------------------------------------------------------
{
    my $big = 'Z' x 8192;
    my $w = worker(sub { $big }, { results => 1, shared => 1, interval => 0.01 });
    my $got = poll(sub { $w->read });
    my $val = $w->value;
    $w->stop;
    ok(defined $got && $got eq $big,
        'with both channels, results read() still gets the full large value');
    is($val, undef,
        'with both channels, shared value() drops the oversized value');
}

# ---------------------------------------------------------------------------
# 9. Small value on both channels: both deliver it.
# ---------------------------------------------------------------------------
{
    my $w = worker(sub { 'hi' }, { results => 1, shared => 1, interval => 0.01 });
    my $got = poll(sub { $w->read });
    my $val = poll(sub { $w->value });
    $w->stop;
    is($got, 'hi', 'small value delivered on results channel');
    is($val, 'hi', 'small value delivered on shared channel');
}

done_testing();
