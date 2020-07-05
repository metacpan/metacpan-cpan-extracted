package Translate::Fluent::Elements::Argument;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(
      named_argument
      inline_expression
    )] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{named_argument}     = delete $args{ NamedArgument };
  $args{inline_expression}  = delete $args{ InlineExpression };

  $class->$orig( %args );
};

sub identifier {
  my ($self) = @_;

  if ($self->named_argument) {
    return $self->named_argument->identifier;
  }

  return;
}

sub translate {
  my ($self, $variables) = @_;

  if ($self->named_argument) {
    return $self->named_argument->translate( $variables );
  } elsif ($self->inline_expression) {
    return $self->inline_expression->translate( $variables );
  }

  return;
}


1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 identifier

this file implements an identifier method to allow to get the name of
an named_argument

=head2 translate

This file implements the translate method for choice variants, but it is not
that interesting.

=cut

