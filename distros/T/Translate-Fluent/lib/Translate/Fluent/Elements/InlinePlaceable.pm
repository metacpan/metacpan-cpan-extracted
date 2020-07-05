package Translate::Fluent::Elements::InlinePlaceable;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(select_expression inline_expression)] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{inline_expression} = delete $args{InlineExpression}
    if $args{InlineExpression};
  $args{select_expression} = delete $args{SelectExpression}
    if $args{SelectExpression};
 
  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  if ($self->select_expression) {
    $self->select_expression->translate( $variables );

  } elsif ($self->inline_expression) {
    $self->inline_expression->translate( $variables );

  } else {
    return '';
  }
}


1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but is not that interesting

=cut

