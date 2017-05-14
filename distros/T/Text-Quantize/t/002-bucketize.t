#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Text::Quantize 'bucketize';

my @data = (
    [26, 24, 51, 77, 21] => {
        16 => 3,
        32 => 1,
        64 => 1,
    },

    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] => {
        0 => 1,
        1 => 1,
        2 => 2,
        4 => 4,
        8 => 3,
    },

    [-4, -3, -2, -1, 0, 1, 2, 3, 4] => {
        -4 => 1,
        -2 => 2,
        -1 => 1,
        0  => 1,
        1  => 1,
        2  => 2,
        4  => 1,
    },
);

plan tests => @data / 2;
while (my ($input, $expected) = splice(@data, 0, 2)) {
    my $buckets = bucketize($input, { add_endpoints => 0 });
    is_deeply($buckets, $expected, "bucketize(@$input)");
}

