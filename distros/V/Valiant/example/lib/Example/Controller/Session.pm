package Example::Controller::Session;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub new_entity :Via('*Root') At('login/...')  QueryModel(LoginQuery) ($self, $c, $user, $q) {
  $c->redirect_to_action('*home') && $c->detach if $user->authenticated; # Don't bother if already logged in
  $c->view('HTML::Login', user => $user);
  $c->view->post_login_redirect($q->post_login_redirect) if $q->has_post_login_redirect;
}

  sub init :GET Via('new_entity') At('/init') Name(Login) ($self, $c) {
    return $c->view->set_http_ok;
  }

  sub create :POST Via('new_entity') At('') BodyModel(LoginRequest) ($self, $c, $request) {
    return $c->view->set_http_bad_request unless $c->authenticate($request->person);
    return $c->res->redirect($c->view->post_login_redirect) if $c->view->has_post_login_redirect;
    return $c->redirect_to_action('*Home');
  }

sub logout :GET Via('*Private') At('logout') ($self, $c, $user) {
  return $c->logout && $c->redirect_to_action('init');
}

__PACKAGE__->meta->make_immutable;
