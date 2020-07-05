package Translate::Fluent::Elements::Text;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has text => (
  is  => 'ro',
  default => sub { undef },
);


sub translate {
  my ($self, $variables) = @_;

  return $self->text;
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate package, but it is not that interesting

=cut

