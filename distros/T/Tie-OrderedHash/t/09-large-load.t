#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;
use POSIX;

my $N = 10_000;

tie my %h, 'Tie::OrderedHash';
for my $i (0 .. $N - 1) {
    $h{"k$i"} = $i;
}

is(scalar keys %h, $N, "scalar keys: $N");
is($h{k0},          0, 'first value');
is($h{"k" . ($N - 1)}, $N - 1, 'last value');

# `keys` walk gives us insertion order at the boundaries.
my @ks = keys %h;
is($ks[0],     'k0',                 'first key from walk');
is($ks[-1],    "k" . ($N - 1),       'last key from walk');
is(scalar @ks, $N,                   'walk count');

# Spot-check middle.
is($ks[$N / 2], "k" . ($N / 2), 'middle key');

# Random fetches still hit. Pick indices that are well inside any
# plausible N - 42 is always present, and a third-of-the-way-in spot
# scales with N.
my $mid = int($N / 3);
is($h{k42},          42,    'fetch k42');
is($h{"k$mid"},      $mid,  "fetch k$mid");

done_testing;
