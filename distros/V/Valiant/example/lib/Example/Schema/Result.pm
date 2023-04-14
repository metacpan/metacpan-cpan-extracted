package Example::Schema::Result;

use strict;
use warnings;
use base 'DBIx::Class';
use DBIx::Class::_Util 'quote_sub';
use Example::Syntax;

__PACKAGE__->load_components(qw/
  Valiant::Result
  BcryptColumn
  ResultClass::TrackColumns
  Core
  InflateColumn::DateTime
  /);

sub debug($self) {
  $self->result_source->schema->debug;
  return $self;
}

sub debug_off($self) {
  $self->result_source->schema->debug_off;
  return $self;
}

1;
