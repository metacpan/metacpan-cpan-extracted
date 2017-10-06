#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


#<<< notidy

my $null = PDL->null;
my $d0   = PDL->new;
my $d1   = PDL->new( [] );
my $d2   = PDL->new( [], [] );
my $d3   = PDL->new( [ [] ], [ [] ] );

subtest 'validate fiducials' => sub {

    is( $null->ndims, 1, 'null' );
    is( $d0->ndims,   0, '0D' );
    is( $d1->ndims,   1, '1D' );
    is( $d2->ndims,   2, '2D' );
    is( $d3->ndims,   3, '3D' );

};

subtest 'ndims = 0' => sub {

    my $t = Piddle [ ndims => 0 ];

    ok( !$t->check( $null ), 'null' );
    ok(  $t->check( $d0 ),   '0D' );
    ok( !$t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};

subtest 'ndims = 1' => sub {

    my $t = Piddle [ ndims => 1 ];

    ok(  $t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};


subtest 'ndims_min = 1' => sub {

    my $t = Piddle [ ndims_min => 1 ];

    ok(  $t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok(  $t->check( $d3 ),   '3D' );

};

subtest 'ndims_min = 2' => sub {

    my $t = Piddle [ ndims_min => 2 ];

    ok( !$t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok( !$t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok(  $t->check( $d3 ),   '3D' );

};

subtest 'ndims_max = 1' => sub {

    my $t = Piddle [ ndims_max => 1 ];

    ok(  $t->check( $null ), 'null' );
    ok(  $t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );
};

subtest 'ndims_max = 2' => sub {

    my $t = Piddle [ ndims_max => 2 ];

    ok(  $t->check( $null ), 'null' );
    ok(  $t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};


subtest 'ndims_max = 3' => sub {

    my $t = Piddle [ ndims_max => 3 ];

    ok(  $t->check( $null ), 'null' );
    ok(  $t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok(  $t->check( $d3 ),   '3D' );
};


subtest 'ndims_min = 1 && ndims_max = 2' => sub {

    my $t = Piddle [ ndims_min => 1, ndims_max => 2 ];

    ok(  $t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok(  $t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};

subtest 'ndims_min = 1 && ndims_max = 1' => sub {

    my $t = Piddle [ ndims_min => 1, ndims_max => 1 ];

    ok(  $t->check( $null ), 'null' );
    ok( !$t->check( $d0 ),   '0D' );
    ok(  $t->check( $d1 ),   '1D' );
    ok( !$t->check( $d2 ),   '2D' );
    ok( !$t->check( $d3 ),   '3D' );

};


subtest 'illegal constraint specifications' => sub {

    like(
        dies { Piddle [ ndims_min => 2, ndims_max => 0 ] },
         qr/must be <=/,
         'ndims_min > ndims_max',
    );

    like(
        dies { Piddle [ ndims_min => 0, ndims_max => 2, ndims => 3 ] },
         qr/cannot mix/,
         'ndims_min, ndims_max, ndims',
    );

    like(
        dies { Piddle [ ndims_min => 2, ndims => 3 ] },
         qr/cannot mix/,
         'ndims_min, ndims',
    );

    like(
        dies { Piddle [ ndims_max => 0, ndims => 3 ] },
         qr/cannot mix/,
         'ndims_max, ndims',
    );

    like(
        dies { Piddle [ ndims_max => 1.1 ] },
         qr/must be an integer/,
         'ndims_max float',
    );

    like(
        dies { Piddle [ ndims_min => 1.1 ] },
         qr/must be an integer/,
         'ndims_min float',
    );

    like(
        dies { Piddle [ ndims => 1.1 ] },
         qr/must be an integer/,
         'ndims float',
    );

    like(
        dies { Piddle [ ndims_max => 'a' ] },
         qr/must be an integer/,
         'ndims_max string',
    );

    like(
        dies { Piddle [ ndims_min => 'a' ] },
         qr/must be an integer/,
         'ndims_min string',
    );

    like(
        dies { Piddle [ ndims => 'a' ] },
         qr/must be an integer/,
         'ndims string',
    );

};


#>>> tidy once more

done_testing;
