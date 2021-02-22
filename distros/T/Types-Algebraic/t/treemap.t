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

sub tree_map {
    my ($f, $tree) = @_;

    match ($tree) {
        with (Leaf) { return Leaf; }
        with (Node $v $left $right) {
            return Node (
                $f->($v),
                tree_map($f, $left),
                tree_map($f, $right),
            );
        }
    }
}

my $expected =
    Node(10,
        Node(6, Leaf, Node(8, Leaf, Leaf)),
        Node(14, Node(12, Leaf, Leaf), Node(16, Leaf, Leaf)),
    );

my $got = tree_map( sub { my ($v) = @_; return 2 * $v; }, $tree );
is($got, $expected, 'correct result after mapping onto tree');
