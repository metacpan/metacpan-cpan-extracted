package Schema::Nested::Result::PersonRole;

use strict;
use warnings;

use base 'Schema::Result';

__PACKAGE__->table("person_role");

__PACKAGE__->add_columns(
  person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  role_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
);

__PACKAGE__->set_primary_key("person_id", "role_id");

__PACKAGE__->belongs_to(
  person =>
  'Schema::Nested::Result::Person',
  { 'foreign.id' => 'self.person_id' }
);

__PACKAGE__->belongs_to(
  role =>
  'Schema::Nested::Result::Role',
  { 'foreign.id' => 'self.role_id' }
);

__PACKAGE__->accept_nested_for('role', +{find_with_uniques=>1});
__PACKAGE__->validates(role => presence=>1, with=>'unique_role');

sub unique_role {
  my ($self, $attribute_name, $record, $opts) = @_;

  return if $self->in_storage && !$self->is_changed;
  return unless my $result = $self->result_source->resultset
  ->search({person_id=>$self->person_id,'role.label'=>$record->label},{join=>'role'})
  ->single;

  $self->errors->add($attribute_name, \'already has role {{role_label}}', +{%$opts, role_label=>$record->label});
}

sub is_user {
  my $self = shift;
  return $self->role->label eq 'user' ? 1:0;
}

1;
