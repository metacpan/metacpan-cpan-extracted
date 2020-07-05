package Translate::Fluent::Elements::NamedArgument;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(
      identifier
      string_literal
      number_literal
    )] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{identifier}         = delete $args{ Identifier };
  $args{string_literal}     = delete $args{ StringLiteral };
  $args{number_literal}     = delete $args{ NumberLiteral };

  $class->$orig( %args );
};

sub translate {
  my ($self) = @_;

  my $part = $self->string_literal
          // $self->number_literal;

  return ref $part ? $part->translate : $part;
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

