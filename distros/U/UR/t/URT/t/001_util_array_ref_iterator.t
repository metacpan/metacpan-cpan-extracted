#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use above 'UR';


use_ok("UR::Util::ArrayRefIterator");


# Test an array
my @a0 = (1, 2, 3, 4, 5);
my $i0 = UR::Util::ArrayRefIterator->create(\@a0);

for my $v (@a0) {
    is($i0->next(), $v, sprintf('a0 value %s ok', $v));
}

is($i0->next(), undef, 'i0 last value is undef');
is_deeply(\@a0, [1, 2, 3, 4, 5], 'a0 not modified');


# Test an array ref
my $a1 = [6, 7, 8, 9];
my $i1 = UR::Util::ArrayRefIterator->create($a1);

for my $v (@{$a1}) {
    is($i1->next(), $v, sprintf('a1 value %s is ok', $v));
}

is($i1->next(), undef, 'i1 last value is undef');
is_deeply($a1, [6, 7, 8, 9], 'a1 not modified');


# Make sure we can start at an arbitrary position
my $a2 = [10, 11, 12, 13, 14];
my $i2 = UR::Util::ArrayRefIterator->create(arrayref => $a2, position => 2);

for my $v (@{$a2}[2..4]) {
    is($i2->next(), $v, sprintf('a2 value %s is ok', $v));
}

is($i2->next(), undef, 'i2 last value is undef');
is_deeply($a2, [10, 11, 12, 13, 14], 'a2 not modified');


# Make sure we handle position > array length
my $a3 = [15, 16];
my $i3 = UR::Util::ArrayRefIterator->create(arrayref => $a3, position => 3);

is($i3->next(), undef, 'i3 - position > array length is ok');
is_deeply($a3, [15, 16], 'a3 not modified');


# Ensure empty arrays are fine too
my $a4 = [];
my $i4 = UR::Util::ArrayRefIterator->create($a4);

is($i4->next(), undef, 'i4 - empty array->next() is undef');
is_deeply($a4, [], 'a4 not modified');


done_testing();
