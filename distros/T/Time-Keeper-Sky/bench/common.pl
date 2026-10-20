use 5.010;
use strict;
use warnings;
use Benchmark ();

# What every benchmark here shares (the harness Time::Keeper's bench uses):
# time (never a fixed count, which can run under the clock's resolution),
# the best of five, the line that says whether the mark was met, and
# Benchmark's cmpthese table of the best runs.

our $SECONDS = $ENV{TK_BENCH_SECONDS} // 0.5;
our $RUNS    = $ENV{TK_BENCH_RUNS} // 5;
our $FAILED  = 0;

# Modules only an extra library has (DateTime::Format::ISO8601, Devel::Size),
# searched last, so the installed DateTime is the one measured.
push @INC, split /:/, $ENV{TK_BENCH_LIB} if $ENV{TK_BENCH_LIB};

# Calls a second, by Benchmark's countit: as many calls as fill $SECONDS of
# CPU time, less Benchmark's own empty-loop overhead; the best of $RUNS. The
# best run of each, by its label, goes into the cmpthese table done() prints.
our %RESULTS;
sub rate {
    my ($code, $label) = @_;
    my ($best, $best_obj) = (0, undef);
    $code->() for 1 .. 10;
    for (1 .. $RUNS) {
        my $b = Benchmark::countit($SECONDS, $code);
        my $cpu = $b->cpu_p;
        next unless $cpu > 0;
        my $r = $b->iters / $cpu;
        ($best, $best_obj) = ($r, $b) if $r > $best;
    }
    $RESULTS{$label} = $best_obj if defined $label && $best_obj && !$RESULTS{$label};
    return $best;
}

sub fmt_rate { my ($r) = @_; $r >= 1e6 ? sprintf('%.2fM/s', $r / 1e6) : $r >= 1e3 ? sprintf('%.1fk/s', $r / 1e3) : sprintf('%.0f/s', $r) }

# One mark: how many times faster ours must be ("faster" is more than 1),
# or undef where the other cannot do it.
sub mark {
    my ($what, $mine, $theirs, $need, $who) = @_;
    my $ratio = $mine / $theirs;
    my $ok = $ratio > $need || ($need == 1 && $ratio > 1);
    $FAILED++ unless $ok;
    printf "%-4s %-44s %10s  %-12s %10s  %6.1fx  (mark %s)\n", $ok ? 'PASS' : 'FAIL', $what, fmt_rate($mine), $who,
        fmt_rate($theirs), $ratio, $need == 1 ? 'faster' : "${need}x";
    return $ok;
}

# A quantity where less is better (milliseconds, bytes): ours must be at most
# that of the other divided by $need (1: no more).
sub mark_less {
    my ($what, $mine, $theirs, $need, $who, $unit) = @_;
    my $ratio = $theirs / $mine;
    my $ok = $need == 1 ? $mine <= $theirs : $ratio >= $need;
    $FAILED++ unless $ok;
    printf "%-4s %-44s %10s  %-12s %10s  %6.1fx  (mark %s)\n", $ok ? 'PASS' : 'FAIL', $what, "$mine $unit", $who,
        "$theirs $unit", $ratio, $need == 1 ? 'no more' : "${need}x less";
    return $ok;
}

sub done {
    if (keys %RESULTS > 1) {
        print "\n";
        Benchmark::cmpthese(\%RESULTS);
        print "\n";
    }
    exit($FAILED ? 1 : 0);
}

1;
