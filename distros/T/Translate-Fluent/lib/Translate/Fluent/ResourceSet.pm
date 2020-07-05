package Translate::Fluent::ResourceSet;

use Moo;

has resources => (
  is  => 'rw',
  default => sub { {} },
);

sub add_resource {
  my ($self, $resource) = @_;

  $self->resources->{ $resource->identifier } = $resource;

}

sub translate {
  my ($self, $res_id, $variables) = @_;

  my $res = $self->resources->{ $res_id };

  return unless $res and $res->isa("Translate::Fluent::Elements::Message");

  return $res->translate( { %{$variables//{}}, __resourceset => $self} );
}

sub get_term {
  my ($self, $term_id) = @_;

  my $res = $self->resources->{ $term_id };
  return unless $res->isa("Translate::Fluent::Elements::Term");

  return $res;
}

sub get_message {
  my ($self, $message_id) = @_;

  my $res = $self->resources->{ $message_id };
  return unless $res->isa("Translate::Fluent::Elements::Message");

  return $res;
}

1;

__END__

=head1 NAME

Translate::Fluent::ResourceSet - a set of translation resources 

=head1 SYNOPSIS

  my $resource_set = Translate::Fluent->parse_file( "filename.flt" );
  my $variables = {};

  print $resource_set->translate('some-string', $variables );

=head1 DESCRIPTION

C<Translate::Fluent::ResourceSet> groups multiple translation resources,
often from a single file, and allow you to get translations from them,
even when they need other resources in the resource set.

=head1 METHODS

=head2 add_resource( $resource )

C<add_resource> can be used to add one resource to an existing ResourceSet.

while this can be used externally, it is intended for internal use.

=head2 translate( $res_id, $variables )

Translate a message.

  my $text = $resource_set->translate( 'some-message-id', $variables );

=head2 get_term( $term_id )

Returns a Term object with the id $term_id. This can be useful, but is
intended for internal use.

=head2 get_message( $message_id )

Returns a Message object with the id $message_id. This can be useful, but is
intended for internal use.

=head1 SEE MORE

This file is part of L<Translate::Fluent> - version, license and more general
information can be found in its documentation.

=cut

