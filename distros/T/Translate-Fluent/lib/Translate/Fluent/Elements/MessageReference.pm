package Translate::Fluent::Elements::MessageReference;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(
      identifier
      attribute_accessor
    )] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{identifier}         = delete $args{ Identifier };
  $args{attribute_accessor} = delete $args{ AttributeAccessor };

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  my $message = $variables->{__resourceset}->get_message( $self->identifier );
  return unless $message;

  if ($self->attribute_accessor) {
    $message = $message->get_attribute_resource(
                  $self->attribute_accessor->identifier
                );
  }

  return unless $message;

  # Not sure if this should be called with no variables
  #   or with the variables the parent was called with
  #   so going with the later for now.
  return $message->translate( $variables );
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

