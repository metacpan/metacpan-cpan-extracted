#!/usr/bin/perl

# this test file borrowed from Tie::Array::PackedC by demerphq

use strict;
use warnings;

use Test::More tests => 223;

BEGIN {
    use_ok( 'Tie::Array::Packed' );
}

for my $packer (qw(c C F f d i I j J s! S! l! L! n N v)) {

    SKIP: {
            skip("packing format $packer unsupported on this perl", 12)
                unless eval { pack $packer, 1 || 1 };

            my $class = "Tie::Array::Packed::$packer";

            my $tie = $class->make(1 .. 20 );
            my $obj = tied(@$tie);
            isa_ok( $tie, 'ARRAY', 'make returned an object that' );
            isa_ok( $obj, 'Tie::Array::Packed', 'the tied object' );
            is( "@$tie",    "@{[1..20]}", "All $packer" );
            is( $tie->[0],  1,            "Zero index $packer" );
            is( $tie->[3],  4,            "Intermediate index $packer" );
            is( $tie->[19], 20,           "Last index $packer" );
            is( $tie->[-1], 20,           "Last index (-1) $packer" );
            is( $tie->[20], undef,        "Out of bounds $packer" );

            push @$tie, 10;

            is( $tie->[20], 10, 'Pushed' );
            is( pop @$tie,  10, 'Popped' );
            is( @$tie,      20, 'Count' );
            is( $#$tie,     19, 'Count 2' );
        };
}

for my $packer (qw(F f d)) {
    my $class = "Tie::Array::Packed::$packer";

    my $float = $class->make(1 .. 20 );
    isa_ok( tied(@$float), $class, '$float' );
    isa_ok( tied(@$float), "Tie::Array::Packed", '$float' );
    is( "@$float", "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20", "All (Number)" );
    $float->[0] = 1.414;
    is( sprintf( "%0.3f", $float->[0] ), sprintf( "%0.3f", 1.414 ), 'Float check' );
    ok( exists( $float->[0] ), '$float->[0] exists' );
    ok( !exists( $float->[20] ), '$float->[1] not exists' );
    is( delete( $float->[1] ), 2, 'Delete returns correctly' );
    is( $float->[1], 0, 'Deleted record is 0' );

}

my ( $s, @a ) = eval { pack "j*", 1 .. 5 };
# diag("length \$s: ".length($s));

SKIP: {
    skip("packing format j unsupported on this perl", 1)
        unless defined $s;

    tie @a, 'Tie::Array::Packed::Integer', $s, reverse 1 .. 4;
    is( "@a", "4 3 2 1 5", "Doc check 1 - Initialization overlap" );
};

$s = pack "l!*", 1 .. 5;
tie @a, 'Tie::Array::Packed::LongNative', $s, reverse 1 .. 4;
is( "@a", "4 3 2 1 5", "Doc check 1 - Initialization overlap" );
$a[5] = 10;
is ($a[5],10, "Store into \$array[\@array] works");
isnt( $s, tied(@a)->string, "Doc check 2 - Real versus method string access" );

$a[7] = 11;
is ($a[7],11, "Store past end of \@array works ");
is ($a[6],0, "Store past end of \@array works (intermediate goes to 0) ");

