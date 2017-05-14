#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Text::Quantize;

my $first_line = __LINE__ + 2;
my @data = (
    [26, 24, 51, 77, 21] => [8, 128],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] => [-1, 16],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]     => [-1, 16],
    [0, 1, 2, 3, 4, 5, 6, 7, 8]        => [-1, 16],
    [0, 1, 2, 3, 4, 5, 6, 7]           => [-1, 8],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]    => [0, 16],
    [2, 3, 4, 5, 6, 7, 8, 9, 10]       => [1, 16],
    [3, 4, 5, 6, 7, 8, 9, 10]          => [1, 16],
    [4, 5, 6, 7, 8, 9, 10]             => [2, 16],
    [5, 6, 7, 8, 9, 10]                => [2, 16],
    [6, 7, 8, 9, 10]                   => [2, 16],
    [-4, -3, -2, -1, 0, 1, 2, 3, 4]    => [-8, 8],
    [-4, -3, -2, -1, 0]                => [-8, 1],
    [-4, -3, -2, -1]                   => [-8, 0],
    [-4, -3, -2, -1]                   => [-8, 0],
    [-4, -3, -2]                       => [-8, -1],
);

plan tests => @data / 2;
my $i = 0;
while (my ($input, $expected) = splice(@data, 0, 2)) {
    my $buckets = Text::Quantize::bucketize($input, { add_endpoints => 0 });
    my ($min, $max) = Text::Quantize::_endpoints_for($buckets);

    is_deeply([$min, $max], $expected, "_endpoints_for \@data line " . ($first_line + $i));

    ++$i;
}

