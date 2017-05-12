package WWW::Formspring::Response;

use Moose;

use WWW::Formspring;
use WWW::Formspring::Question;

extends('WWW::Formspring::Question');

has 'answer' => ( is => 'rw', isa => 'Str' );

sub respond {
    my ($self) = @_;

    WWW::Formspring->inbox_respond($self);
}

__PACKAGE__->meta->make_immutable;

1;
