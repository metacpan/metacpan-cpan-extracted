use strict;
use warnings;

package Example::Schema::Result;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/
  Valiant::Result
  Core
  InflateColumn::DateTime/);

sub debug {
  my ($self) = @_;
  $self->result_source->schema->debug;
  return $self;
}

sub debug_off {
  my ($self) = @_;
  $self->result_source->schema->debug_off;
  return $self;
}
1;
