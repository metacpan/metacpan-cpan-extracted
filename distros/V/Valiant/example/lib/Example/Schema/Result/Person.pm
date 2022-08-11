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

__PACKAGE__->has_many(
  todos =>
  'Example::Schema::Result::Todo',
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

__PACKAGE__->validates(credit_cards => (set_size=>{min=>2, max=>4}, on=>'account' ));
__PACKAGE__->accept_nested_for('credit_cards', +{allow_destroy=>1});

__PACKAGE__->validates(person_roles => (set_size=>{min=>1}, on=>'account' ));
__PACKAGE__->accept_nested_for('person_roles', {allow_destroy=>1});

__PACKAGE__->accept_nested_for('profile');

sub available_states($self) {
  return $self->result_source->schema->resultset('State');
}

sub available_roles($self) {
  return $self->result_source->schema->resultset('Role');
}

sub authenticated($self) {
  return $self->username && $self->in_storage ? 1:0;
}

sub authenticate($self, $request) {
  my ($username, $password) = $request->get('username', 'password');
  my $found = $self->result_source->resultset->find({username=>$username});
  %$self = %$found if $found;

  return 1 if $self->in_storage && $self->check_password($password);
  $self->errors->add(undef, 'Invalid login credentials');
  return 0;
}

sub registered($self) {
  return $self->username &&
    $self->first_name &&
    $self->last_name &&
    $self->password &&
    $self->in_storage ? 1:0;
}

sub account($self) {
  $self->result_source->resultset->account_for($self);
}

sub new_todo($self) {
  return $self->todos->new_result(+{status=>'active'});
}

sub request_todos($self, $request) {
  my $todos = $self->todos->available->newer_first;
  $todos = $todos->filter_by_request($request);
  return $todos;
}

# Update from request object methods

sub register($self, $request) {
  $self->set_columns_recursively($request->nested_params)
    ->set_columns_recursively(+{
        person_roles=>[{role=>{label=>'user'}}],
      })
    ->insert_or_update;

  return $self->registered;
}

sub update_account($self, $request) {
  $self->context('account')->update($request->nested_params);
}

1;
