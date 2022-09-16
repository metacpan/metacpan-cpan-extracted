package Example::Controller::Register;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub register :Chained(../unauth) CaptureArgs(0) ($self, $c, $user) {
  return $c->redirect_to_action('#home') && $c->detach if $user->registered;
  $c->next_action($user);
}

  sub create :Chained(register) Args(0) PathPart('') Verbs(GET, POST) ($self, $c, $user) {
    $c->view('HTML::Register', registration => $c->model('RegistrationForm', model=>$user));
  }

    sub POST :Action RequestModel(RegistrationRequest) ($self, $c, $request) {    
      return $c->user->register($request) ?
        $c->redirect_to_action('#login') :
          $c->view->set_http_bad_request;
    }

__PACKAGE__->meta->make_immutable; 
