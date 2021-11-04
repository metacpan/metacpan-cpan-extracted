#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;

my $null = PDL->null;
my $d0   = PDL->new;
my $d1   = PDL->new( [] );
my $d2   = PDL->new( [], [] );
my $d3   = PDL->new( [ [] ], [ [] ] );


#<<< notidy

subtest 'NDArray1D' => sub {

    my $t = NDArray1D;

    ok(  $t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

    $t = NDArray1D[ empty => 1 ];

    ok( $t->check( $d1 ),
        'NDArray1d[ empty => 1 ]',
      );

};

subtest 'NDArray2D' => sub {

    my $t = NDArray2D;

    ok( !$t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok( !$t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};

subtest 'NDArray3D' => sub {

    my $t = NDArray3D;

    ok( !$t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok( !$t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok(  $t->check( $d3 ),   '3D' );

};


#>>> tidy once more
done_testing;
