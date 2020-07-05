package Translate::Fluent::Elements::BlockPlaceable;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has inline_placeable => (
  is  => 'ro',
  default => sub { undef },
);

sub translate {
  my ($self, $variables) = @_;

  if ($self->inline_placeable) {
    return $self->inline_placeable->translate( $variables );
  }

  return '';
}

1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but is not that interesting.

=cut

