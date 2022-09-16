package Example::Controller::Session;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub login : Chained(../root) Args(0) Verbs(GET,POST) Name(login) ($self, $c) {
  $c->redirect_to_action('#home') && $c->detach if $c->user->authenticated; # Don't bother if already logged in
  $c->view('HTML::Login', user => $c->user);
}

  sub POST :Action RequestModel(LoginRequest) ($self, $c, $request) {
    $c->view->post_login_redirect($request->post_login_redirect)
      if $request->has_post_login_redirect;

    return $c->view->set_http_bad_request unless $c->authenticate($request->person);
    return $c->res->redirect($request->post_login_redirect) if $request->has_post_login_redirect;
    return $c->res->redirect($c->req->uri) if $c->action ne $self->action_for('login');  # ->detach case from the auth action
    return $c->redirect_to_action('#home');
  }

sub logout :GET Chained(../auth) PathPart(logout) Args(0) ($self, $c, $user) {
  return $c->logout && $c->redirect_to_action('#login');
}

__PACKAGE__->meta->make_immutable;
