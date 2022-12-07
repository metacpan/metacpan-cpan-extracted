package Example::Controller::Session;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub login : Chained(../root) Args(0) Verbs(GET,POST) Name(login) RequestModel(LoginQuery) ($self, $c, $q) {
  $c->redirect_to_action('#home') && $c->detach if $c->user->authenticated; # Don't bother if already logged in
  $c->view('HTML::Login', user => $c->user);
  $c->view->post_login_redirect($q->post_login_redirect) if $q->has_post_login_redirect;
  $c->next_action($q);
}

  sub POST :Action RequestModel(LoginRequest) ($self, $c, $request, $q) {
    return $c->view->set_http_bad_request unless $c->authenticate($request->person);
    return $c->res->redirect($q->post_login_redirect) if $q->has_post_login_redirect;
    return $c->redirect_to_action('#home');
  }

sub logout :GET Chained(../auth) PathPart(logout) Args(0) ($self, $c, $user) {
  return $c->logout && $c->redirect_to_action('#login');
}

__PACKAGE__->meta->make_immutable;
