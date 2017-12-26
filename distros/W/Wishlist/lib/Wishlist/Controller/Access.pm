package Wishlist::Controller::Access;
use Mojo::Base 'Mojolicious::Controller';

sub login {
  my $c = shift;
  my $username = $c->param('username');
  my $password = $c->param('password');
  if ($c->model->check_password($username, $password)) {
    $c->session->{username} = $username;
  }
  $c->redirect_to('/');
}

sub register {
  my $c = shift;
  my $username = $c->param('username');
  my $user = {
    username => $username,
    password => $c->param('password'),
    name     => $c->param('name'),
  };
  warn Mojo::Util::dumper $user;
  unless(eval { $c->model->add_user($user); 1 }) {
    $c->app->log->error($@) if $@;
    return $c->render(text => 'Could not create user', status => 400);
  }
  $c->session->{username} = $username;
  $c->redirect_to('/');
};

sub logout {
  my $c = shift;
  $c->session(expires => 1);
  $c->redirect_to('/');
}

1;

