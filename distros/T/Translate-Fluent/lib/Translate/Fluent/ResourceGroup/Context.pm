package Translate::Fluent::ResourceGroup::Context;

use Moo;

has context => (
  is => 'ro',
  default => sub { {} },
);

has resgroup => (
  is => 'ro',
);

sub get_term {
  my ($self, $term_id) = @_;

  return $self->resgroup->get_term( $term_id, $self->context );
}

sub get_message {
  my ($self, $message_id) = @_;

  return $self->resgroup->get_message( $message_id, $self->context );
}

1;

__END__

=head1 NAME

Translate::Fluent::ResourceGroup::Context - ResourceSet emulation

=head1 SYNOPSIS

DO NOT USE DIRECTLY

=head1 DESCRIPTION

This package is used internally by L<Translate::Fluent::ResourceGroup> to
provide the functionality of L<Translate::Fluent::ResourceSet> and keep track
of what is the context of the original translation request.

This is needed so that all sub-translations needed to finish a translation
request are done in a consistent way. This object, unlike the ResourceSet,
does not keep any translation objects, it only delegates getting this objects
from L<Translate::Fluent::ResourceGroup> with the right context.

=head1 METHODS IMPLEMENTED

This package only implements the methods of L<Translate::Fluent:ResourceSet>
needed during translation calls. See that class for details on those methods.

=head2 get_term( $term_id )

=head2 get_message( $message_id )

=head1 SEE MORE

This file is part of L<Translate::Fluent> - version, license and more general
information can be found in its documentation

=cut

