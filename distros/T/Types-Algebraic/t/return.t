#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

use Types::Algebraic;

data Direction = N | E | S | W;

sub next_direction {
    my $d = shift;
    match ($d) {
        with (N) { return E; }
        with (E) { return S; }
        with (S) { return W; }
        with (W) { return N; }
    }
}

is( next_direction(N), E, "N -> E" );
is( next_direction(E), S, "E -> S" );
is( next_direction(S), W, "S -> W" );
is( next_direction(W), N, "W -> N" );

sub get_offset {
    my $d = shift;
    match ($d) {
        with (N) { return ( 1,  0); }
        with (E) { return ( 0,  1); }
        with (S) { return (-1,  0); }
        with (W) { return ( 0, -1); }
    }
}

is_deeply( [ get_offset(N) ], [ 1,  0], "offset N" );
is_deeply( [ get_offset(E) ], [ 0,  1], "offset E" );
is_deeply( [ get_offset(S) ], [-1,  0], "offset S" );
is_deeply( [ get_offset(W) ], [ 0, -1], "offset W" );
