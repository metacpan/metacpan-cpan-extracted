package Translate::Fluent::Elements::Variant;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(
      identifier
      pattern
    )] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{identifier}   = delete $args{ Identifier };
  $args{pattern}      = delete $args{ Pattern };

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  return $self->pattern->translate( $variables );
}

1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

This file implements the translate method for choice variants, but it is not
that interesting.

=cut

