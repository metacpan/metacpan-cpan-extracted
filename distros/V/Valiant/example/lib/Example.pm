package Example;

use Catalyst;
use Moose;
use Example::Syntax;

__PACKAGE__->setup_plugins([qw/
  Session
  Session::State::Cookie
  Session::Store::Cookie
  RedirectTo
  URI
  Errors
  ServeFile
  CSRFToken
/]);

__PACKAGE__->config(
  disable_component_resolution_regex_fallback => 1,
  using_frontend_proxy => 1,
  'Plugin::Session' => { storage_secret_key => 'abc123' },
  'Plugin::CSRFToken' => { auto_check =>1, default_secret => 'abc123' },
  'Model::Schema' => {
    traits => ['SchemaProxy'],
    schema_class => 'Example::Schema',
    connect_info => {
      dsn => "dbi:SQLite:dbname=@{[ __PACKAGE__->path_to('var','db.db') ]}",
    }
  },
);

__PACKAGE__->setup();
  
has users => (
  is => 'ro',
  lazy => 1,
  default => sub($c) { $c->model('Schema::Person') },
);

has user => (
  is => 'rw',
  lazy => 1,
  required => 1,
  builder => 'get_user_from_session',
  clearer => 'clear_user',
);

# This should probably return an empty user rather than undef
sub get_user_from_session($self) {
  my $id = $self->session->{user_id} // return $self->users->unauthenticated_user;
  my $person = $self->users->find_by_id($id) // $self->remove_user_from_session && die "Bad ID '$id' in session";
  return $person;
}

sub persist_user_to_session ($self, $user) {
  $self->session->{user_id} = $user->id;
}

sub remove_user_from_session($self) {
  delete $self->session->{user_id};
}

sub authenticate($self, @args) {
  my $authenticated = $self->user->authenticate(@args);
  $self->persist_user_to_session($self->user) if $authenticated;
  return $authenticated;
}

sub logout($self) {
  $self->remove_user_from_session;
  $self->clear_user;
}

sub build_view($self, @args) {
  my ($view_name) = @{$self->action->attributes->{View}};
  my $view = $self->view($view_name, @args);
  $self->stash(current_view_instance=>$view);
  return $view;
}

__PACKAGE__->meta->make_immutable();
