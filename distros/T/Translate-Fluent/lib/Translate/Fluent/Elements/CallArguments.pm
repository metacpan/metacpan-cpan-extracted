package Translate::Fluent::Elements::CallArguments;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has argument_list => (
  is  => 'ro',
  default => sub { [] },
);


sub to_variables {
  my ( $self, $variables ) = @_;

  return unless $self->argument_list;

  return $self->argument_list->to_variables;
}

1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 to_variables

this package implements a to_variables method, but is not that interesting

=cut

