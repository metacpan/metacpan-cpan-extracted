package Example::Schema::Result::PersonRole;

use strict;
use warnings;

use base 'Example::Schema::Result';

__PACKAGE__->table("person_role");
__PACKAGE__->load_components(qw/Valiant::Result/);

__PACKAGE__->add_columns(
  person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  role_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
);

__PACKAGE__->set_primary_key("person_id", "role_id");

__PACKAGE__->belongs_to(
  person =>
  'Example::Schema::Result::Person',
  { 'foreign.id' => 'self.person_id' }
);

__PACKAGE__->belongs_to(
  role =>
  'Example::Schema::Result::Role',
  { 'foreign.id' => 'self.role_id' }
);

sub is_user {
  my $self = shift;
  return $self->role->label eq 'user' ? 1:0;
}

1;
