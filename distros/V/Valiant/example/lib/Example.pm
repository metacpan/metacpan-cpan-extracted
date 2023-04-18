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
  default_view => 'HTML',
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

after 'setup_components' => sub ($class) {
  use Devel::Dwarn;
  my @controllers = $class->controllers;
  foreach my $controller (@controllers) {
    #warn "Controller: $controller";
    my @methods_with_attributes = "${class}::Controller::${controller}"->meta->get_all_methods_with_attributes;
    foreach my $method (@methods_with_attributes) {
      #warn "  Method: @{[ $method->name ]}";
      my @attributes = $method->attributes;
      #Dwarn \@attributes; 
    }
    #Dwarn \@methods_with_attributes;
  }
};

__PACKAGE__->setup();
  
has user => (
  is => 'rw',
  lazy => 1,
  required => 1,
  builder => 'get_user_from_session',
  clearer => 'clear_user',
);

sub get_user_from_session($self) {
  my $id = $self->model('Session')->user_id // return $self->model('Schema::Person')->unauthenticated_user;
  my $person = $self->model('Schema::Person')->find_by_id($id) // $self->logout && die "Bad ID '$id' in session";
  return $person;
}

sub persist_user_to_session ($self, $user) {
  $self->model('Session')->user_id($user->id);
}

sub authenticate($self, @args) {
  my $authenticated = $self->user->authenticate(@args);
  $self->persist_user_to_session($self->user) if $authenticated;
  return $authenticated;
}

sub logout($self) {
  $self->model('Session')->logout;
  $self->clear_user;
}

# Path Helpers

## Contacts

sub edit_contact_path($self, $c, $contact, $attrs=+{}) {
  return $self->ctx->uri('edit', [$contact->id], $attrs);
}

sub contacts_path($c, @args) {
  return $c->uri('/contacts', @args);
}


## Register

sub register_init_path($c, @args) {
  return $c->uri('/register/init', @args);
}

__PACKAGE__->meta->make_immutable();
