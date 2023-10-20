package Schema::Nested::Result::Person;

use base 'Schema::Result';

__PACKAGE__->table("person");

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
  username => { data_type => 'varchar', is_nullable => 0, size => 48 },
  first_name => { data_type => 'varchar', is_nullable => 0, size => 24 },
  last_name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  state_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
);

__PACKAGE__->validates(username => presence=>1, length=>[3,24], format=>'alpha_numeric', unique=>{skip_if_undef=>1});
__PACKAGE__->validates(first_name => (presence=>1, length=>[2,24]));
__PACKAGE__->validates(last_name => (presence=>1, length=>[2,48]));

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['username']);


__PACKAGE__->belongs_to(
  state =>
  'Schema::Nested::Result::State',
  { 'foreign.id' => 'self.state_id' }
);

__PACKAGE__->has_many(
  person_roles =>
  'Schema::Nested::Result::PersonRole',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  meetings =>
  'Schema::Nested::Result::Meeting',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->many_to_many('roles' => 'person_roles', 'role');
__PACKAGE__->accept_nested_for('state');
__PACKAGE__->validates(state => (presence=>1));
__PACKAGE__->validates(person_roles => (presence=>1));

__PACKAGE__->validates(person_roles => (presence=>1, set_size=>{min=>1}, on=>'min'));
__PACKAGE__->validates(roles => (presence=>1, set_size=>{min=>1}, on=>'min'));


__PACKAGE__->accept_nested_for('person_roles', +{find_with_uniques=>1, allow_destroy=>1});
__PACKAGE__->accept_nested_for('roles', +{find_with_uniques=>1, allow_destroy=>1});

sub default_roles {
  my ($self, $attribute_name, $record, $opts) = @_;
  $self->errors->add($attribute_name, 'Must be at least a user', $opts)
    unless $record->is_user;
}

1;
