package Translate::Fluent::Elements::Message;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(identifier pattern attributes)] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{ identifier } = delete $args{ Identifier };
  $args{ pattern }    = delete $args{ Pattern };
  $args{ attributes } = delete $args{ Attribute };
  $args{ attributes } = [ $args{ attributes } ]
    unless ref $args{ attributes } eq 'ARRAY';

  $args{ attributes } = [ map { { Attribute => $_ } }
                          @{ $args{ attributes } }
                        ];

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  return $self->pattern->translate( $variables );
}

sub get_attribute_resource {
  my ($self, $attr_id) = @_;

  for my $attr ( @{ $self->attributes||[] } ) {
    return $attr
      if $attr->identifier eq $attr_id;

  }

  return;
}


1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

=head2 get_attribute_resource

this package implements the methods translate and get_attribute_resource, but
it is not that interesting

=cut

