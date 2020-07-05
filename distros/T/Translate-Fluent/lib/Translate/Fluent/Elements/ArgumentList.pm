package Translate::Fluent::Elements::ArgumentList;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has argument => (
  is  => 'ro',
  default => sub { [] },
);

around BUILDARGS => sub {
  my ($orig, $self, %args) = @_;

  $args{ argument } = delete $args{ Argument };
  $args{ argument } = [ $args{ argument } ]
    unless ref $args{argument} eq 'ARRAY';

  $args{ argument } = [map { {Argument => $_ } }
                        @{ $args{ argument } } ];

  $self->$orig( %args );
};

sub to_variables {
  my ($self, $variables ) = @_;

  my %vars;

  my $pos = 0;
  for my $arg (@{ $self->argument // [] }) {
    my $id = $arg->identifier;
    unless ($id ) {
      $id = "position_$pos";
      $pos++;
    }
    $vars{ $id } = $arg->translate( $variables );
  }

  return \%vars;
}


1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 to_variables

This file implements the to_variables, to facilitate reusage of normal
translation  code when calling attributes with parameters, but it is not
that interesting.

=cut

