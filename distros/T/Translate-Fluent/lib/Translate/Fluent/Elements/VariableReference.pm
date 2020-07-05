package Translate::Fluent::Elements::VariableReference;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has identifier => (
  is  => 'ro',
  default => sub { undef },
);

sub translate {
  my ($self, $variables) = @_;

#  use Data::Dumper;
#  print STDERR Dumper($self, $variables);

  return $variables->{ $self->identifier };
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

