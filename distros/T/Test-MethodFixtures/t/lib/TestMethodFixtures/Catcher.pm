package TestMethodFixtures::Catcher;

use strict;
use warnings;

use base 'TestMethodFixtures::Dummy';

__PACKAGE__->mk_accessors( qw/ stored retrieved / );

sub store {
    my ( $self, $args ) = @_;

    $self->stored( $args );

    return $self->SUPER::store( $args );
}

sub retrieve {
    my ( $self, $args ) = @_;

    $self->retrieved( $args );

    return $self->SUPER::retrieve( $args );
}

sub reset {
    my $self = shift;

    $self->stored(undef);
    $self->retrieved(undef);
}

1;

