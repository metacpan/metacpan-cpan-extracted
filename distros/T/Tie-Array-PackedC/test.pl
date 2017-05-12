use strict;
use warnings;

our @DEBUG;
use Test::More tests => 28;

BEGIN {

    #@DEBUG=qw(DEBUG 1);
    use_ok( 'Tie::Array::PackedC', qw( packed_array packed_array_string ) );
    use_ok( 'Tie::Array::PackedC', qw( Double d ), @DEBUG );
}

my $tie = packed_array( 1 .. 20 );
my $obj = tied(@$tie);
isa_ok( $tie, 'ARRAY', 'packed_array returned an object that' );
isa_ok( $obj, 'Tie::Array::PackedC', 'the tied object' );
is( "@$tie",    "@{[1..20]}", "All" );
is( $tie->[0],  1,            'Zero index' );
is( $tie->[3],  4,            'Intermediate index' );
is( $tie->[19], 20,           'Last index' );
is( $tie->[-1], 20,           'Last index (-1)' );
is( $tie->[20], undef,        'Out of bounds' );

push @$tie, 10;

is( $tie->[20], 10, 'Pushed' );
is( pop @$tie,  10, 'Popped' );
is( @$tie,      20, 'Count' );
is( $#$tie,     19, 'Count 2' );

@DEBUG and $obj->hex_dump;

my $float = Tie::Array::PackedC::Double::packed_array( 1 .. 20 );
isa_ok( tied(@$float), 'Tie::Array::PackedC::Double', '$float' );
is( "@$float", "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20", "All (Double)" );
$float->[0] = 1.414;
is( sprintf( "%0.3f", $float->[0] ), sprintf( "%0.3f", 1.414 ), 'Float check' );
ok( exists( $float->[0] ), '$float->[0] exists' );
ok( !exists( $float->[20] ), '$float->[1] not exists' );
is( delete( $float->[1] ), 2, 'Delete returns correctly' );
is( $float->[1], 0, 'Deleted record is 0' );

my ( $s, @a ) = pack "l!*", 1 .. 5;
tie @a, 'Tie::Array::PackedC', $s, reverse 1 .. 4;
is( "@a", "4 3 2 1 5", "Doc check 1 - Initialization overlap" );
$a[5] = 10;
is ($a[5],10, "Store into \$array[\@array] works");
isnt( $s, tied(@a)->string, "Doc check 2 - Real versus method string access" );

$a[7] = 11;
is ($a[7],11, "Store past end of \@array works ");
is ($a[6],0, "Store past end of \@array works (intermediate goes to 0) ");
my $l1=length(${tied(@a)});
tied(@a)->trim;
my $l2=length(${tied(@a)});
isnt($l1,$l2,"Trim trimmed");
is( "@a", "4 3 2 1 5 10 0 11", "Trim didn't corrupt" );
