package Example::Counter;

use strict;
use warnings;

sub slim_constructor_signature {
  return { parameters => ['int'] };
}

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['int'], return => 'int' }
    if $method eq 'add_amount';
  return { parameters => [], return => 'int' }
    if $method eq 'value';
  return;
}

sub new {
  my ($class, $initial_value) = @_;
  return bless { value => $initial_value }, $class;
}

sub add_amount {
  my ($self, $amount) = @_;
  $self->{value} += $amount;
  return $self->{value};
}

sub value { $_[0]{value} }

1;
