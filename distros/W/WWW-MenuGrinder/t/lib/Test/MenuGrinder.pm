package Test::MenuGrinder;

use Moose;

extends 'WWW::MenuGrinder';

has 'path' => (
  is => 'ro',
  lazy => '1',
  default => sub { 'user/view' }
);

sub get_variable {
  my ($self, $varname) = @_;

  return $self->variables->{$varname};
}

sub variables {
  my ($self) = @_;

  return {
    username => "Suzy Queue"
  };
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
