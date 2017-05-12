package Catty::Model::Foo;

use Moose;
extends 'Catalyst::Model';

has general => (
    is      => 'ro',
    default => 'general',
);

has context_specific => (
    is     => 'ro',
    writer => '_set_context_specific',
);

sub ACCEPT_CONTEXT {
    my ( $self, $c, @args ) = @_;

    $self->_set_context_specific( $c->stash->{foo} );

    return $self;
}

1;
