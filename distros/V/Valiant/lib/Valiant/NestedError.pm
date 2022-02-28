package Valiant::NestedError;

use Moo;

extends 'Valiant::Error';

has 'inner_error' => (
  is => 'ro',
  required => 1,
  handles => { message => 'message' }
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $options = $class->$orig(@args);

  return +{ %$options, inner_error=>$options->{options}{inner_error} };


};

1;
