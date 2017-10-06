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

subtest 'Piddle1D' => sub {

    my $t = Piddle1D;

    ok(  $t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

    $t = Piddle1D[ empty => 1 ];

    ok( $t->check( $d1 ),
        'Piddle1d[ empty => 1 ]',
      );

};

subtest 'Piddle2D' => sub {

    my $t = Piddle2D;

    ok( !$t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok( !$t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};

subtest 'Piddle3D' => sub {

    my $t = Piddle3D;

    ok( !$t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok( !$t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok(  $t->check( $d3 ),   '3D' );

};


#>>> tidy once more
done_testing;
