#! perl

use Test2::V0;

use Types::PDL -types;

use PDL::Lite;


my @tests = ( {
        shape => '3, 2, 1',
        pdl   => PDL->new( [ [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ] ),
        label => 'Piddle',
        type  => \&Piddle,
    },
    {
        shape => '3, 2, 1',
        pdl   => PDL->new( [ [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ] ),
        label => 'Piddle3D',
        type  => \&Piddle3D,
    },
    {
        shape => '3, 2',
        pdl   => PDL->new( [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ),
        label => 'Piddle',
        type  => \&Piddle,
    },
    {
        shape => '3, 2',
        pdl   => PDL->new( [ [ 1, 2, 3 ], [ 1, 2, 3 ] ] ),
        label => 'Piddle2D',
        type  => \&Piddle2D,
    },
    {
        shape => '3',
        pdl   => PDL->new( [ 1, 2, 3 ] ),
        label => 'Piddle',
        type  => \&Piddle,
    },
    {
        shape => '3',
        pdl   => PDL->new( [ 1, 2, 3 ] ),
        label => 'Piddle1D',
        type  => \&Piddle1D,
    },
);

for my $test ( @tests ) {

    my ( $shape, $pdl, $type ) = @$test{ 'shape', 'pdl', 'type' };

    ok( $test->{type}->( [ shape => $test->{shape} ] )->check( $test->{pdl} ),
        $test->{label} . ': ' . $test->{shape} )
      or note $test->{pdl}->shape;

}



done_testing;
