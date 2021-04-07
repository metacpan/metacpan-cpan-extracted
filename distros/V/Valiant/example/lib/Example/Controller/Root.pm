package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Devel::Dwarn; 

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) { } 

  sub not_found :Chained(root) PathPart('') Args { $_[1]->detach_error(404) }
  
  sub auth: Chained(root) PathPart('') CaptureArgs() {
    my ($self, $c) = @_;
    return if $c->user_exists;
    $c->redirect_to_action('login');
    $c->detach;
  }

  sub register :Chained(root) PathPart('register') Args(0) {
    my ($self, $c) = @_;
    $c->redirect_to_action('home') if $c->user_exists;
    $c->stash(person => my $model = $c->model('Schema::Person')->new_result($c->req->body_data||+{}));
    $model->insert if $c->req->method eq 'POST';
    return $c->redirect_to_action('login') if $model->in_storage;
  }

    sub home :Chained(auth) PathPart('home') Args(0) {
      my ($self, $c) = @_;
      $c->res->body('logged in! See <a href="/profile">Profile</a> or <a href="/logout">Logout</a>');  
    }

    sub profile :Chained(auth) PathPart('profile') Args(0) {
      my ($self, $c) = @_;
      my %params = %{$c->req->body_data||+{}};

      $c->stash(person => my $model = $c->model('Schema::Person')
        ->find(
          { 'me.id'=>$c->user->id },
          { prefetch => ['profile', 'credit_cards', {person_roles => 'role' }] }
        )
      );

      $c->stash(build_empty_cc => delete($params{add}));

      if($c->req->method eq 'POST') {
        $params{roles} = [] unless exists $params{roles}; # Handle the delete case
        Dwarn \%params;
        $model->update({%params, __context=>'profile'}) 
      }
    }

    sub logout : Chained(auth) PathPart(logout) Args(0) {
      my ($self, $c) = @_;
      $c->logout;
      $c->redirect_to_action('login');
    }

  sub login : Chained(root) PathPart(login) Args(0) {
    my ($self, $c) = @_;
    $c->stash(error => '');
    if($c->req->method eq 'POST') {
      $c->redirect_to_action('home') if $c->authenticate({
          username=>$c->req->body_data->{username},
          password=>$c->req->body_data->{password},
        });
      $c->stash(error => 'User not found!');
    }
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;

