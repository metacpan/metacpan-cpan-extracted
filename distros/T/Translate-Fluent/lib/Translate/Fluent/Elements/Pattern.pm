package Translate::Fluent::Elements::Pattern;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(pattern_element)] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{Pattern_Element} = delete $args{PatternElement};
  $args{Pattern_Element} = [ $args{Pattern_Element} ]
    unless ref $args{Pattern_Element} eq 'ARRAY';

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_; 
  
  my $res = '';
  for my $elem (@{ $self->pattern_element }) {
    $res .= $elem->translate( $variables );
  }

  return $res;
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

