#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use List::Util qw(reduce);
use Types::Algebraic;

# Pairing heap - http://en.wikipedia.org/wiki/Pairing_heap

data PairingHeap = Empty | Heap :head :subheaps;
data Pair = Pair :left :right;

# merge, O(1)
# Merges two heaps
sub merge {
    my ($h1, $h2) = @_;

    match (Pair($h1, $h2)) {
        with (Pair Empty $h) { return $h; }
        with (Pair $h Empty) { return $h; }
        with (Pair (Heap $e1 $s1) (Heap $e2 $s2)) {
            return $e1 < $e2 ? Heap($e1, [$h2, @$s1])
                             : Heap($e2, [$h1, @$s2]);
        }
    }
}

# insert, O(1)
# Inserts an element into the heap
sub insert {
    my ($e, $h) = @_;
    return merge( Heap($e, []), $h );
}

# find_min, O(1)
# Returns the smallest element of the heap
sub find_min {
    my ($h) = @_;

    match ($h) {
        with (Empty) { die "Empty heap"; }
        with (Heap $e $rest) { return $e; }
    }
}

sub _merge_pairs {
    return Empty unless @_;
    return $_[0] if @_ == 1;

    my ($h1, $h2, @hs) = @_;
    return merge( merge($h1, $h2), _merge_pairs(@hs) );
}

# delete_min, O(lg n) amortized
# Deletes the smallest element of the heap
sub delete_min {
    my ($h) = @_;

    match ($h) {
        with (Empty) { die "Empty heap"; }
        with (Heap $e $rest) { return _merge_pairs(@$rest); }
    }
}

# build, O(n)
# Builds a heap from a list
sub build {
    return reduce { insert($b, $a) } Empty, @_;
}

sub heapsort {
    my $h = build(@_);

    my @result;
    while (1) {
        match ($h) {
            with (Empty) { return @result; }
            default {
                push(@result, find_min($h));
                $h = delete_min($h);
            }
        }
    }
}

my @input = (6,2,7,5,8,1,3,4);

my @expected = (1,2,3,4,5,6,7,8);
my @got = heapsort(@input);

is_deeply(\@got, \@expected, 'sorted correctly');
