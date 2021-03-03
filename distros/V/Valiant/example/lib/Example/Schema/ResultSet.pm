package Example::Schema::ResultSet;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw/
  Helper::ResultSet::Shortcut
  Helper::ResultSet::Me
  Helper::ResultSet::SetOperations
  Helper::ResultSet::IgnoreWantarray
  ResultSet::CallbackInflator
  Valiant::ResultSet
/);

sub to_array {
  my ($self) = @_;
  return $self->search(
    {},
    {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
  )->all;
}

sub debug {
  my ($self) = @_;
  $self->result_source->schema->debug;
  return $self;
}

1;
