use strict;
use warnings;
use 5.10.0;
use Test::More;
use Perlude::Lazy;

plan tests => my $tests;

# very basic test
BEGIN { $tests += 1 }
my $l = enlist { state $n; $n++ };
is( ref $l, 'CODE', 'enlist returns a coderef' );

# check some values
BEGIN { $tests += 3 }
my @v;
( $l, @v ) = $l->();
is_deeply( \@v, [0], 'first item' );
( $l, @v ) = $l->(1);    # peek at the next value
is_deeply( \@v, [1], 'peek at the next item' );
( $l, @v ) = $l->();
is_deeply( \@v, [1], 'next item' );

# peek at a lot of values at once
BEGIN { $tests += 3 }
my $n = int 1000 * rand;
( $l, @v ) = $l->($n);
is( scalar @v, $n, "Peeked at $n items" );
is( $v[-1], 1 + $n, "Last item is " . ( $n + 1 ) );
( $l, @v ) = $l->();
is_deeply( \@v, [2], 'next item' );

# corner cases
BEGIN { $tests += 4 }
( $l, @v ) = $l->(0);
is( scalar @v, 0, 'peek at nothing' );
( $l, @v ) = $l->();
is_deeply( \@v, [3], 'next item' );

( $l, @v ) = $l->(-1);
is( scalar @v, 0, 'peek at nothing (-1)' );
( $l, @v ) = $l->();
is_deeply( \@v, [4], 'next item' );

# bounded list
BEGIN { $tests += 4 }
$l = unfold 0 .. 5;
( $l, @v ) = $l->(6);
is( scalar @v, 6, 'peek at the remaining items' );
( $l, @v ) = $l->();
is_deeply( \@v, [0], 'next item' );
( $l, @v ) = $l->(7);
is( scalar @v, 5, 'peek at more than the remaining total' );
( $l, @v ) = $l->();
is_deeply( \@v, [1], 'next item' );

my @tests;
BEGIN {
@tests = (
    [
        (unfold 0..5),
        [6], [0..5],
        [],  [0],
        [],  [1],
        [6], [2..5],
        [],  [2],
        [],  [3],
        [],  [4],
        [9], [5],
        [],  [5],
        [9], [],
        [],  [],
    ],
    [
        (unfold 0..1),
        [1], [0],
        [2], [0..1],
        [2], [0..1],
        [],  [0],
        [2], [1],
        [],  [1],
        [2], [],
        [],  [],
    ],
    [
        (unfold 0..3),
        [2], [0..1],
        [],  [0],
        [1], [1],
        [],  [1],
        [2], [2..3],
        [],  [2],
        [],  [3],
        [1],  [],
        [],  [],
    ],
    [
        Perlude::Lazy::NIL,
        [],  [],
    ],
);

$tests += @$_ for @tests;
}

my $m = 1;
while (@tests) {
    my $t = shift @tests;
    my $l = shift @$t;
    my $n = 1;
    while (@$t) {
        ($l, my @v) = $l->(@{ shift @$t });
        is_deeply \@v, (shift @$t), "test $m,$n";
        ($l,    @v) = $l->(0);
        is_deeply \@v, [], "test $m,$n: peek 0";
        $n++;
    };
    is $l, Perlude::Lazy::NIL, "end $m";
    $m++;
}

