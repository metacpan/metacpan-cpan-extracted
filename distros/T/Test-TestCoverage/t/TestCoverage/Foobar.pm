package
   TestCoverage::Foobar;

use strict;
use warnings;

use Moose;

has 'attr' => (
    is => 'rw',
    isa => 'Str',
);

sub change {
    my $self = shift;
    $self->attr( $self->attr x 2 );
}

sub BUILD {
    my $self = shift;

    $self->attr( 'foobar' );
}

1;

