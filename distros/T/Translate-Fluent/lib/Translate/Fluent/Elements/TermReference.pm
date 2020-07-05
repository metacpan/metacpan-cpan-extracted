package Translate::Fluent::Elements::TermReference;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(
      identifier
      attribute_accessor
      call_arguments
    )] => (
  is  => 'ro',
  default => sub { undef },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{identifier}         = delete $args{ Identifier };
  $args{attribute_accessor} = delete $args{ AttributeAccessor };
  $args{call_arguments}     = delete $args{ CallArguments };

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  my $res = $variables->{__resourceset}->get_term( $self->identifier );
  return unless $res;

  if ($self->attribute_accessor) {
    $res = $res->get_attribute_resource(
                $self->attribute_accessor->identifier
              );
  }

  return unless $res;

  my $vars = $self->call_arguments
    ? { %{ $self->call_arguments->to_variables }, 
           __resourceset => $variables->{__resourceset}
      }
    : $variables;

  return $res->translate( $vars );
}

1;
__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

