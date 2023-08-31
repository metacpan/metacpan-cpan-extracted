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

__PACKAGE__->many_to_many( roles => 'person_roles', 'role');

__PACKAGE__->has_many(
  todos =>
  'Example::Schema::Result::Todo',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  contacts =>
  'Example::Schema::Result::Contact',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  posts =>
  'Example::Schema::Result::Post',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  comments =>
  'Example::Schema::Result::Comment',
  { 'foreign.person_id' => 'self.id' }
);

__PACKAGE__->has_many(
  viewable_posts2 =>
    'Example::Schema::Result::Post::Viewable',
    sub {
      my $args = shift;
      return 
        +{ },
         { "$args->{foreign_alias}.id" => \[' is not null', $args->{self_result_object}->id ] };
    },
);

sub viewable_posts($self, $search_args = {}) {
  my $schema = $self->result_source->schema;
  return $schema->resultset('Post::Viewable')->search(
    $search_args,
    { bind => [ $self->id ] }
  );
}

__PACKAGE__->validates(username => presence=>1, length=>[3,24], format=>'alpha_numeric', unique=>1);
__PACKAGE__->validates( password => (presence=>1, confirmation => 1,  on=>'create' ));
__PACKAGE__->validates( password => (confirmation => { 
    on => 'update',
    if => 'is_column_changed', # This method defined by DBIx::Class::Row
  }));

__PACKAGE__->validates(first_name => (presence=>1, length=>[2,24]));
__PACKAGE__->validates(last_name => (presence=>1, length=>[2,48]));

__PACKAGE__->validates(credit_cards => (set_size=>{min=>2, max=>4, skip_if_blank=>1} ));
__PACKAGE__->accept_nested_for('credit_cards', +{allow_destroy=>1});

__PACKAGE__->validates(person_roles => (set_size=>{min=>1}, with=>'validate_roles' ));
__PACKAGE__->accept_nested_for('person_roles', {allow_destroy=>1});
__PACKAGE__->accept_nested_for('contacts', {allow_destroy=>1});

__PACKAGE__->accept_nested_for('profile');
__PACKAGE__->accept_nested_for('roles');

__PACKAGE__->validates_with(sub {
  my ($self, $opts) = @_;
  $self->errors->add(undef, "No MEga!!!!!") if (($self->last_name||'') eq 'mega');
});

sub validate_roles($self, $attribute_name, $value, $opt) {

  # Tricky since you want to use the cached rows.  This could likely be optimized
  # to avoid hitting the DB to get role labels but this is example code I don't
  # want to preoptimize.

  my %names = map {
    $_->role->label => 1
  } grep {
    ! $_->is_marked_for_deletion;  # In this case the validations only want proposed new selected roles
  } @{ $value->get_cache || [] };

  if($names{guest}) {
    $self->errors->add($attribute_name, "'guest' is exclusive", $opt) if scalar(keys %names) > 1;
  }
  if($names{admin} && $names{superuser}) {
    $self->errors->add($attribute_name, "can't be both 'admin' and 'superuser'", $opt) 
  }
}

sub authenticated($self) {
  return $self->username && $self->in_storage ? 1:0;
}

sub authenticate($self, $request) {
  my ($username, $password) = $request->get('username', 'password');
  my $found = $self->result_source->resultset->find({username=>$username});

  if($found && $found->in_storage && $found->check_password($password)) {
    %$self = %$found;
    return $self;
  } else {
    $self->errors->add(undef, 'Invalid login credentials');
    $self->username($username) if defined($username);
    return 0;
  }
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

sub accessible_people($self) {
  $self->result_source->resultset->accessible_people_for($self);
}

sub request_todos($self, $request) {
  my $todos = $self->todos->available->newer_first;
  return $todos = $todos->filter_by_request($request);
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

## There's are proxied to other resultsets for now but we expect that
## ecentually they could be impacted by the current user.

sub states {
  my $self = shift;
  return $self->result_source->schema->resultset('State');
}

sub viewable_roles {
  my $self = shift;
  return $self->result_source->schema->resultset('Role');
}

sub employment_options {
  my $self = shift;
  return $self->result_source->schema->resultset('Employment');
}

1;
