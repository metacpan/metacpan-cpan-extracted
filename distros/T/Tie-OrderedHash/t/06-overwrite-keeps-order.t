#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Storing a value at an existing key updates the value but does NOT
# change that key's position.  This is the headline Tie::IxHash
# invariant - the same Perl code works whether you migrate to
# Tie::OrderedHash or stay on Tie::IxHash.

tie my %h, 'Tie::OrderedHash';
$h{a} = 1;
$h{b} = 2;
$h{a} = 3;            # update a, should stay at position 0
$h{c} = 4;
$h{b} = 'CHANGED';    # update b, should stay at position 1

is_deeply([keys %h],   [qw(a b c)],         'overwrite preserves order');
is_deeply([values %h], [3, 'CHANGED', 4],   'overwrite updates values');

# Overwrite all values back.
$h{$_} = "v_$_" for keys %h;
is_deeply([keys %h], [qw(a b c)], 'after second overwrite: same order');
is_deeply([values %h], [qw(v_a v_b v_c)], 'after second overwrite: new values');

done_testing;
