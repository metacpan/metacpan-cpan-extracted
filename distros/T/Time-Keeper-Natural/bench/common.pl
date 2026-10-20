use 5.010;
use strict;
use warnings;
use utf8;
use Benchmark ();
use Time::HiRes ();

# What every benchmark here shares: a rate taken with Benchmark over a fixed
# time (never a fixed count, which can run under the clock's resolution), the
# best of five, and a line that says whether the mark was met. The marks were
# set in plan_time_keeper_natural/11-benchmarks-and-the-gate.md before any
# number was seen. Benchmark subtracts its own empty-loop overhead, which
# flatters a fast call; `wall` gives the plain wall-clock rate beside it.

our $SECONDS = $ENV{TKN_BENCH_SECONDS} // 0.5;
our $RUNS    = $ENV{TKN_BENCH_RUNS} // 5;
our $FAILED  = 0;
binmode STDOUT, ':encoding(UTF-8)';

sub rate {
    my ($code) = @_;
    my $best = 0;
    $code->() for 1 .. 10;
    for (1 .. $RUNS) {
        my $b = Benchmark::countit($SECONDS, $code);
        my $cpu = $b->cpu_p;
        next unless $cpu > 0;
        my $r = $b->iters / $cpu;
        $best = $r if $r > $best;
    }
    return $best;
}

sub wall {
    my ($code) = @_;
    my $best = 0;
    for (1 .. $RUNS) {
        my ($n, $t0) = (0, [Time::HiRes::gettimeofday()]);
        my $el;
        do { $code->() for 1 .. 100; $n += 100 } while (($el = Time::HiRes::tv_interval($t0)) < $SECONDS);
        $best = $n / $el if $n / $el > $best;
    }
    return $best;
}

sub fmt_rate { my ($r) = @_; $r >= 1e6 ? sprintf('%.2fM/s', $r / 1e6) : $r >= 1e3 ? sprintf('%.1fk/s', $r / 1e3) : sprintf('%.0f/s', $r) }

# A rate that must reach the mark; the wall-clock rate is printed beside it.
sub mark_rate {
    my ($what, $code, $need) = @_;
    my ($r, $w) = (rate($code), wall($code));
    my $ok = $r >= $need;
    $FAILED++ unless $ok;
    printf "%-4s %-40s %10s  (wall clock %s)  mark %s\n", $ok ? 'PASS' : 'FAIL', $what, fmt_rate($r), fmt_rate($w), fmt_rate($need);
    return $ok;
}

# A quantity that must not pass the mark (milliseconds, bytes).
sub mark_most {
    my ($what, $mine, $most, $unit) = @_;
    my $ok = $mine <= $most;
    $FAILED++ unless $ok;
    printf "%-4s %-40s %10s  mark at most %s %s\n", $ok ? 'PASS' : 'FAIL', $what, "$mine $unit", $most, $unit;
    return $ok;
}

sub skip { my ($what, $why) = @_; printf "SKIP %-40s %s\n", $what, $why }

sub pinned {
    require Time::Keeper;
    return Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
}

sub done { exit($FAILED ? 1 : 0) }

1;
