#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


my @tests = ( {
        shape => '3, 2, 1',
        pdl   => PDL->new( [ [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ] ),
        label => 'NDArray',
        type  => \&NDArray,
    },
    {
        shape => '3, 2, 1',
        pdl   => PDL->new( [ [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ] ),
        label => 'NDArray3D',
        type  => \&NDArray3D,
    },
    {
        shape => '3, 2',
        pdl   => PDL->new( [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ),
        label => 'NDArray',
        type  => \&NDArray,
    },
    {
        shape => '3, 2',
        pdl   => PDL->new( [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ),
        label => 'NDArray2D',
        type  => \&NDArray2D,
    },
    {
        shape => '3',
        pdl   => PDL->new( [ 1, 2, 3 ] ),
        label => 'NDArray',
        type  => \&NDArray,
    },
    {
        shape => '3',
        pdl   => PDL->new( [ 1, 2, 3 ] ),
        label => 'NDArray1D',
        type  => \&NDArray1D,
    },
);

for my $test ( @tests ) {

    my ( $shape, $pdl, $type ) = @$test{ 'shape', 'pdl', 'type' };

    ok( $test->{type}->( [ shape => $test->{shape} ] )->check( $test->{pdl} ),
        $test->{label} . ': ' . $test->{shape} )
      or note $test->{pdl}->shape;

}



done_testing;
