package Example;

use Catalyst;
use Valiant::I18N;
use Example::Base;

__PACKAGE__->setup_plugins([qw/
  Session
  Session::State::Cookie
  Session::Store::Cookie
  RedirectTo
  URI
  Errors
  StructuredParameters
/]);

__PACKAGE__->config(
  disable_component_resolution_regex_fallback => 1,
  'Plugin::Session' => { storage_secret_key => 'abc123' },
  'Model::Schema' => {
    traits => ['SchemaProxy'],
    schema_class => 'Example::Schema',
    connect_info => {
      dsn => "dbi:SQLite:dbname=@{[ __PACKAGE__->path_to('var','db.db') ]}",
    }
  },
);

__PACKAGE__->setup();

sub authenticate($self, $username='', $password='') {
  my $user = $self->model('Schema::Person')->authenticate($username, $password);
  $self->session->{user_id} = $user->id unless $user->has_errors;
  return $user; 
}

sub user($self) {
  return $self->{_user} ||= do {
    my $id = $self->session->{user_id} // return;
    my $person = $self->model('Schema::Person')->find({id=>$id}) // return;
  };
}

sub logout($self) { delete $self->session->{user_id} }

__PACKAGE__->meta->make_immutable();
