#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
#use Test::Exception;

use Types::Algebraic;

data Direction = N | E | S | W;

data Operation = Move :direction :distance;

#throws_ok sub {
#    my $foo = Move(N, 10);
#    match ($foo) {
#        with (Move $dist NonExistentConstructor) { ... }
#    }
#} qr/Unknown constructor 'NonExistentConstructor'/, 'error on match with unknown constructor';

my @program = (
    Move(10, N),
    Move(20, S),
    Move(30, E),
    Move(40, W),
);

my ($x, $y) = (0, 0);
my @trace;
for my $op (@program) {
    match ($op) {
        with (Move $dist N) { $y += $dist; }
        with (Move $dist E) { $x += $dist; }
        with (Move $dist S) { $y -= $dist; }
        with (Move $dist W) { $x -= $dist; }
    }

    push(@trace, [$x, $y]);
}

my @expected = (
    [0, 10],
    [0, -10],
    [30, -10],
    [-10, -10],
);

is_deeply(\@trace, \@expected, "correct trace followed");
