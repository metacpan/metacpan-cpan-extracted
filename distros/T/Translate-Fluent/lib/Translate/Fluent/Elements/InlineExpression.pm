package Translate::Fluent::Elements::InlineExpression;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(
      string_literal
      number_literal
      function_reference
      message_reference
      term_reference
      variable_reference
      inline_placeable
    )] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{string_literal}     = delete $args{ StringLiteral };
  $args{number_literal}     = delete $args{ NumberLiteral };
  $args{function_reference} = delete $args{ FunctionReference };
  $args{message_reference}  = delete $args{ MessageReference };
  $args{term_reference}     = delete $args{ TermReference };
  $args{variable_reference} = delete $args{ VariableReference };
  $args{inline_placeable}   = delete $args{ InlinePlaceable };

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  my $part
    =     $self->string_literal
      ||  $self->number_literal
      ||  $self->function_reference
      ||  $self->message_reference
      ||  $self->term_reference
      ||  $self->variable_reference
      ||  $self->inline_placeable;

  return ref $part ? $part->translate( $variables ) : $part;
  
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

