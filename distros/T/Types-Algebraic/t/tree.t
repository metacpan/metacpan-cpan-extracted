#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use Types::Algebraic;

data Tree = Node :value :left :right | Leaf;

#        5
#   3        7
#     4   6    8

my $tree =
    Node(5,
        Node(3, Leaf, Node(4, Leaf, Leaf)),
        Node(7, Node(6, Leaf, Leaf), Node(8, Leaf, Leaf)),
    );

sub traverse {
    my ($t, $path) = @_;

    match ($t) {
        with (Leaf) { return [$path, "L"]; }
        with (Node $v $left $right) {
            return (
                traverse($left,  "${path}l"),
                [$path, $v],
                traverse($right, "${path}r"),
            );
        }
    }
}

my @result = traverse($tree, '');
my @expected = (
    ['ll', 'L'],
    ['l', 3],
    ['lrl', 'L'],
    ['lr', 4],
    ['lrr', 'L'],
    ['', 5],
    ['rll', 'L'],
    ['rl', 6],
    ['rlr', 'L'],
    ['r', 7],
    ['rrl', 'L'],
    ['rr', 8],
    ['rrr', 'L'],
);

is_deeply(\@result, \@expected, 'correct value from tree traversal');
