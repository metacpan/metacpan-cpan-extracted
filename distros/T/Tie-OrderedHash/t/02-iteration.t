#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# FIRSTKEY / NEXTKEY produce keys in insertion order.  Same single-
# cursor semantics as Tie::IxHash: a fresh `keys` walk resets the
# cursor.

tie my %h, 'Tie::OrderedHash';
$h{$_} = ord $_ for split //, 'abcde';

# Plain `keys` walk.
is_deeply([keys %h], [qw(a b c d e)], 'keys: insertion order');

# `each` walk pulls pairs in order.
my @pairs;
while (my ($k, $v) = each %h) {
    push @pairs, [$k, $v];
}
is_deeply(\@pairs,
          [['a', 97], ['b', 98], ['c', 99], ['d', 100], ['e', 101]],
          'each: pairs in insertion order');

# values walk same order.
is_deeply([values %h], [97, 98, 99, 100, 101], 'values: insertion order');

# A `keys %h` mid-`each` resets the cursor (Tie::IxHash semantics).
keys %h;            # reset
my ($k1, $v1) = each %h;
is($k1, 'a', 'each after keys-reset starts at first key');
my ($k2, $v2) = each %h;
is($k2, 'b', 'each continues to second key');
keys %h;            # reset again
my ($k3, $v3) = each %h;
is($k3, 'a', 'reset cursor goes back to first');

done_testing;
