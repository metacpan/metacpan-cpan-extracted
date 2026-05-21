#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# DELETE on a middle key removes it and shifts higher-index entries
# down by one; subsequent operations see a clean contiguous order.

tie my %h, 'Tie::OrderedHash';
$h{$_} = uc $_ for qw(a b c d e);

is_deeply([keys %h], [qw(a b c d e)], 'before delete');

is(delete $h{c}, 'C', 'DELETE returns the value');
is_deeply([keys %h], [qw(a b d e)], 'after delete c: order preserved');

# Indices internally must be 0..3 now.  Probe by adding a new key
# and confirming it's appended at the end (would fail if internal
# index for a key still pointed at the old slot).
$h{f} = 'F';
is_deeply([keys %h], [qw(a b d e f)], 'new key appended at end');
is($h{a}, 'A', 'a still resolves correctly');
is($h{e}, 'E', 'e still resolves correctly');

# Delete the first key, then add another.
delete $h{a};
$h{g} = 'G';
is_deeply([keys %h], [qw(b d e f g)], 'after delete a + add g');

# Delete the last key.
delete $h{g};
is_deeply([keys %h], [qw(b d e f)], 'after delete last');

# Delete all.
delete $h{$_} for keys %h;
is(scalar keys %h, 0, 'all deleted: empty');

# Re-add.
$h{x} = 'X';
is_deeply([keys %h], ['x'], 're-add after empty');

done_testing;
