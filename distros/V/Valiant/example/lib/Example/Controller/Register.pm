package Example::Controller::Register;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub new_entity :Via('*Public') At('register/...') ($self, $c, $user) {
  return $c->redirect_to_action('#home') && $c->detach if $user->registered;
  $c->view('HTML::Register', registration => $user);
  $c->action->next($user);
}

  sub init :GET Via('new_entity') At('init') ($self, $c, $user) {
    return $c->view->set_http_ok;
  }

  sub create :POST Via('new_entity') At('') BodyModel(RegistrationRequest) ($self, $c, $user, $request) {
    return $user->register($request) ?
      $c->redirect_to_action('*Login') :
        $c->view->set_http_bad_request;
  }

__PACKAGE__->meta->make_immutable; 
