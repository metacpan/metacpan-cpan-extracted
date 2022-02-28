package Example::Schema::Result::Person;

use Example::Syntax;
use base 'Example::Schema::Result';

__PACKAGE__->table("person");

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
  username => { data_type => 'varchar', is_nullable => 0, size => 48 },
  first_name => { data_type => 'varchar', is_nullable => 0, size => 24 },
  last_name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  password => {
    data_type => 'varchar',
    is_nullable => 0,
    size => 64,
    bcrypt => 1,
  },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['username']);

__PACKAGE__->might_have(
  profile =>
  'Example::Schema::Result::Profile',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  credit_cards =>
  'Example::Schema::Result::CreditCard',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  person_roles =>
  'Example::Schema::Result::PersonRole',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->validates(username => presence=>1, length=>[3,24], format=>'alpha_numeric', unique=>1);
__PACKAGE__->validates( password => (presence=>1, confirmation => 1,  on=>'create' ));
__PACKAGE__->validates( password => (confirmation => { 
    on => 'update',
    if => 'is_column_changed', # This method defined by DBIx::Class::Row
  }));

__PACKAGE__->validates(first_name => (presence=>1, length=>[2,24]));
__PACKAGE__->validates(last_name => (presence=>1, length=>[2,48]));

__PACKAGE__->validates(credit_cards => (set_size=>{min=>2, max=>4}, on=>'profile' ));
__PACKAGE__->accept_nested_for('credit_cards', +{allow_destroy=>1});

__PACKAGE__->validates(person_roles => (set_size=>{min=>1}, on=>'profile' ));
__PACKAGE__->accept_nested_for('person_roles', {allow_destroy=>1});

__PACKAGE__->accept_nested_for('profile');

# TODO: I think these can be removed
sub registered {
  my $self = shift;
  return $self->validated && $self->valid;
}

sub default_roles {
  my ($self, $attribute_name, $record, $opts) = @_;
  $self->errors->add($attribute_name, 'Must be at least a user', $opts)
    unless $record->is_user;
}

1;
