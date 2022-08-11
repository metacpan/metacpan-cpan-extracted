package Example::Controller::Session;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub login : Chained(/root) Args(0) Does(Verbs) Name(login) View(HTML::Login) ($self, $c) {
  $c->redirect_to_action('#home') && $c->detach if $c->user->authenticated; # Don't bother if already logged in
  $c->build_view(user => $c->user);
}

  sub GET :Action ($self, $c) { return $c->view->set_http_ok  }

  sub POST :Action RequestModel(LoginRequest) ($self, $c, $request) {
    return $c->authenticate($request) ?
      $c->redirect_to_action('#home') :
        $c->view->set_http_bad_request 
  }

  sub logout : Chained(/auth) PathPart(logout) Args(0) ($self, $c) {
    return $c->logout && $c->redirect_to_action('#login');
  }

__PACKAGE__->meta->make_immutable;
