use Test::More;
use strict;
use warnings;
use Perlude::Lazy;

my @pass =
( [ 3, enlist { } ]
, [ 4, unfold( 0 .. 10 ), [ 0 .. 3 ], [ 4 .. 7 ], [ 8 .. 10 ] ]
, [ 2.5, unfold( 0 .. 6 ), [ 0 .. 2 ], [ 3 .. 5 ], [ 6 ] ]
);

my @fail =
( [ 0, enlist { } ]
, [ -1, unfold( 0 .. 10 ) ]
, [ 'a', unfold( 0 .. 10 ) ]
);

plan tests => @pass + 2 * @fail;

for my $t (@pass) {
    my ( $n, $i, @r ) = @$t;
    is_deeply( [ fold tuple $n, \&$i ], \@r, "tuple $n" );
}

for my $t (@fail) {
    my ( $n, $i ) = @$t;
    ok( !eval { tuple $n, \&$i; 1 }, "tuple $n FAIL" );
    like(
        $@,
        qr/^\Q$n\E is not a valid parameter for tuple\(\) at /,
        "error message for tuple $n"
    );
}

