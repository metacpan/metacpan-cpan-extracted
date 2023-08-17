package Example;

use Catalyst;
use Moose;
use Example::Syntax;
use Valiant::I18N; # Needed to load $HOME/locale

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
      #dsn => "dbi:Pg:dbname=contacts;host=localhost;port=5432",
      #user => "contact_dbuser",
      #password => "abc123",
    },
  },
);

__PACKAGE__->setup();
  
has user => (
  is => 'rw',
  lazy => 1,
  required => 1,
  builder => '_get_user_from_session',
  clearer => 'clear_user',
);

sub _get_user_from_session($self) {
  return $self->model('Schema::Person')->find($self->req->header('X-Devuser'))
    if $self->req->header('X-Devuser') && $self->debug;

  my $id = $self->model('Session')->user_id // return $self->model('Schema::Person')->unauthenticated_user;
  my $person = $self->model('Schema::Person')->find($id) // $self->logout && die "Bad ID '$id' in session";
  return $person;
}

sub persist_user_to_session ($self, $user) {
  $self->model('Session')->user_id($user->id);
}

sub authenticate($self, $user, @args) {
  $self->persist_user_to_session($user) if my $authenticated = $user->authenticate(@args);
  return $authenticated;
}

sub logout($self) {
  $self->model('Session')->logout;
  $self->clear_user;
}

__PACKAGE__->meta->make_immutable();
