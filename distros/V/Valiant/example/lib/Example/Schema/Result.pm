use strict;
use warnings;

package Example::Schema::Result;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/
  IntrospectableM2M
  Core
  InflateColumn::DateTime/);

sub debug {
  my ($self) = @_;
  $self->result_source->schema->debug;
  return $self;
}

1;
