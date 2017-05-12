package WWW::Phanfare::Class::Role::Attributes;
use Moose::Role;
use MooseX::Method::Signatures;

# Store attribute values in _attr.
# Use _set_attr to set one attributes key=>value
# Ise attributes to get list of all attribute keys
#
has '_attr' => (
  traits    => ['Hash'],
  is        => 'ro',
  isa       => 'HashRef[Str]',
  default   => sub { {} },
  handles   => {
    _set_attr  => 'set',
    attributes => 'keys',
  },
);

# Set multiple attributes at once
#
method setattributes ( HashRef $data ) {
  my %attr = map {
    ref $data->{$_}
      ? ()
      : ( $_ => $data->{$_} )
  } keys %$data;
  $self->_set_attr( %attr );
}

# Get or set an attribute
#
method attribute ( Str $key, Str $value? ) {
  # Read
  return $self->_attr->{$key} unless defined $value;

  # Write
  if ( $self->can('_update') ) {
    defined $self->_update( $key => $value ) or return undef;
    $self->_set_attr( $key => $value );
  } else {
    return undef;
  }
}


=head1 NAME

WWW::Phanfare::Class::Role::Attributes - Node Attributes

=head1 DESCRIPTION

Adds attribute accessors to nodes that support attributes.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
