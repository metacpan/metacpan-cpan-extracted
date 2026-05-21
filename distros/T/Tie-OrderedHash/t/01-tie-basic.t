#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Basic tied-hash interface: STORE / FETCH / EXISTS / DELETE / CLEAR
# round-trip cleanly, and `keys` walks insertion order.

tie my %h, 'Tie::OrderedHash';

# Empty after construction.
is(scalar keys %h, 0, 'empty after tie');
ok(!exists $h{anything}, 'EXISTS on empty: false');
is($h{missing}, undef, 'FETCH missing key: undef');

# STORE.
$h{z} = 1;
$h{a} = 2;
$h{m} = 'three';
is(scalar keys %h, 3, 'three keys after STORE');

# FETCH.
is($h{z}, 1,       'FETCH z');
is($h{a}, 2,       'FETCH a');
is($h{m}, 'three', 'FETCH m (string value)');

# EXISTS.
ok( exists $h{z},   'EXISTS hits');
ok(!exists $h{nope}, 'EXISTS miss');

# Insertion order on `keys`.
is_deeply([keys %h],   ['z', 'a', 'm'],     'keys: insertion order');
is_deeply([values %h], [1, 2, 'three'],     'values: insertion order');

# DELETE returns the value and removes the key.
is(delete $h{a}, 2, 'DELETE returns deleted value');
ok(!exists $h{a},   'DELETE removed key');
is_deeply([keys %h], ['z', 'm'], 'order preserved after delete');

# DELETE missing returns undef.
is(delete $h{never}, undef, 'DELETE missing: undef');

# CLEAR via %h = ().
%h = ();
is(scalar keys %h, 0, 'CLEAR via empty assignment');

# Reassign and verify.
$h{x} = 99;
is_deeply([keys %h], ['x'], 'after CLEAR, single new key');
is($h{x}, 99,               'value persisted after re-add');

done_testing;
