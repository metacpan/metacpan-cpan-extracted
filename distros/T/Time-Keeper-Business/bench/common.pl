use 5.010;
use strict;
use warnings;
use Benchmark ();

# What every benchmark here shares: a rate taken with Benchmark over a fixed
# time (never a fixed count, which can run under the clock's resolution),
# the best of five, the line that says whether the mark was met, and
# Benchmark's cmpthese table of the best runs. The marks were set in
# plan_time_keeper_business/00-overview.md (B14) before any number was seen.

our $SECONDS = $ENV{TK_BENCH_SECONDS} // 0.5;
our $RUNS    = $ENV{TK_BENCH_RUNS} // 5;
our $FAILED  = 0;

# Modules only an extra library has (the CPAN competitors, Devel::Size),
# searched last.
if ($ENV{TK_BENCH_LIB}) {
    require Config;
    push @INC, map { ("$_/lib/perl5/$Config::Config{archname}", "$_/lib/perl5", $_) } split /:/, $ENV{TK_BENCH_LIB};
}

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

# A mark on our rate alone: at least that many calls a second.
sub mark_rate {
    my ($what, $mine, $need) = @_;
    my $ok = $mine >= $need;
    $FAILED++ unless $ok;
    printf "%-4s %-44s %10s  (mark %s)\n", $ok ? 'PASS' : 'FAIL', $what, fmt_rate($mine), fmt_rate($need);
    return $ok;
}

# One mark against another module: how many times faster ours must be.
sub mark {
    my ($what, $mine, $theirs, $need, $who) = @_;
    my $ratio = $mine / $theirs;
    my $ok = $ratio > $need;
    $FAILED++ unless $ok;
    printf "%-4s %-44s %10s  %-22s %10s  %6.1fx  (mark %sx)\n", $ok ? 'PASS' : 'FAIL', $what, fmt_rate($mine), $who, fmt_rate($theirs), $ratio, $need;
    return $ok;
}

# A quantity where less is better: ours must be at most the bound, or at
# most the other's divided by $need.
sub mark_less {
    my ($what, $mine, $bound, $need, $who, $unit) = @_;
    my $ok = $need == 1 ? $mine <= $bound : $bound / $mine >= $need;
    $FAILED++ unless $ok;
    printf "%-4s %-44s %10s  %-22s %10s  (mark %s)\n", $ok ? 'PASS' : 'FAIL', $what, "$mine $unit", $who, "$bound $unit", $need == 1 ? 'no more' : "${need}x less";
    return $ok;
}

# A competitor that is not installed: one line, no mark.
sub absent {
    my ($who, $what) = @_;
    printf "info %s is not installed (TK_BENCH_LIB): no %s comparison\n", $who, $what;
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
