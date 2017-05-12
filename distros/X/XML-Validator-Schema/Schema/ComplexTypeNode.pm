package XML::Validator::Schema::ComplexTypeNode;
use strict;
use warnings;

use base 'XML::Validator::Schema::ElementNode';

=head1 NAME

XML::Validator::Schema::ComplexTypeNode

=head1 DESCRIPTION

This is an internal module used by XML::Validator::Schema to represent
complexType nodes derived from XML Schema documents.

=cut

sub compile {
    my ($self) = shift;
    $self->SUPER::compile();

    # register in the library if this is a named type
    $self->root->{type_library}->add(name => $self->{name},
                                     obj  => $self)
      if $self->{name};
}

1;
