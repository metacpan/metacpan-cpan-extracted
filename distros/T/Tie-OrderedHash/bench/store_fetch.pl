#!/usr/bin/env perl
# bench/store_fetch.pl -- compare Tie::OrderedHash to Tie::IxHash
# and a plain HV across insert + lookup workloads.
#
# Run from dist root after `perl Makefile.PL && make`:
#
#   perl -Mblib bench/store_fetch.pl

use 5.010;
use strict;
use warnings;
use Time::HiRes qw(time);
use Tie::OrderedHash;

eval { require Tie::IxHash; 1 }
    or die "Tie::IxHash not installed; required for the bench\n";

my $N = $ENV{BENCH_N} || 100_000;
say "Bench N = $N\n";

# ---- insert -------------------------------------------------------

sub bench_insert {
    my ($label, $cb) = @_;
    my $t0 = time;
    $cb->();
    my $dt = time - $t0;
    printf "  %-22s  %7.3f s   %.0f ops/s\n",
        $label, $dt, $N / $dt;
    return $dt;
}

say "INSERT (\$h{\$key} = \$val for $N pairs):";

my $t_oh = bench_insert("Tie::OrderedHash", sub {
    tie my %h, 'Tie::OrderedHash';
    for my $i (0 .. $N - 1) { $h{"k$i"} = $i; }
});

my $t_ix = bench_insert("Tie::IxHash",      sub {
    tie my %h, 'Tie::IxHash';
    for my $i (0 .. $N - 1) { $h{"k$i"} = $i; }
});

my $t_hv = bench_insert("plain HV",         sub {
    my %h;
    for my $i (0 .. $N - 1) { $h{"k$i"} = $i; }
});

printf "\n  OrderedHash vs IxHash: %.2fx faster\n", $t_ix / $t_oh;
printf   "  OrderedHash vs HV:     %.2fx slower\n", $t_oh / $t_hv;

# ---- lookup -------------------------------------------------------

say "\nLOOKUP (fetch every key in random order):";

# Build the populated structures once.
tie my %oh, 'Tie::OrderedHash';
tie my %ix, 'Tie::IxHash';
my %hv;
for my $i (0 .. $N - 1) {
    $oh{"k$i"} = $i;
    $ix{"k$i"} = $i;
    $hv{"k$i"} = $i;
}

# Random key order (reused across all three).
my @order = map { "k" . int(rand $N) } 1 .. $N;

sub bench_lookup {
    my ($label, $href) = @_;
    my $t0 = time;
    my $sum = 0;
    $sum += ($href->{$_} // 0) for @order;
    my $dt = time - $t0;
    printf "  %-22s  %7.3f s   %.0f ops/s   sum=%d\n",
        $label, $dt, $N / $dt, $sum;
    return $dt;
}

my $l_oh = bench_lookup("Tie::OrderedHash", \%oh);
my $l_ix = bench_lookup("Tie::IxHash",      \%ix);
my $l_hv = bench_lookup("plain HV",         \%hv);

printf "\n  OrderedHash vs IxHash: %.2fx faster\n", $l_ix / $l_oh;
printf   "  OrderedHash vs HV:     %.2fx slower\n", $l_oh / $l_hv;

# ---- iterate ------------------------------------------------------

say "\nITERATE (full keys+lookup):";

sub bench_iterate {
    my ($label, $href) = @_;
    my $t0 = time;
    my $sum = 0;
    for my $k (keys %$href) {
        $sum += $href->{$k};
    }
    my $dt = time - $t0;
    printf "  %-22s  %7.3f s   %.0f ops/s   sum=%d\n",
        $label, $dt, $N / $dt, $sum;
    return $dt;
}

my $i_oh = bench_iterate("Tie::OrderedHash", \%oh);
my $i_ix = bench_iterate("Tie::IxHash",      \%ix);
my $i_hv = bench_iterate("plain HV",         \%hv);

printf "\n  OrderedHash vs IxHash: %.2fx faster\n", $i_ix / $i_oh;
printf   "  OrderedHash vs HV:     %.2fx slower\n", $i_oh / $i_hv;
