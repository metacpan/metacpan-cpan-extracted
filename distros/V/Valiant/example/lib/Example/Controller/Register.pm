package Example::Controller::Register;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

##  This data is scoped to the controller for which it makes sense, as opposed to
## how the stash is scoped to the entire request.  Plus you reduce the risk of typos
## in calling the stash which breaks stuff in hard to figure out ways.  Basically
## we have a strongly typed controller with a clear data access API.

sub root :Chained(/root) PathPart(register) Args(0) Does(Verbs) View(HTML::Register)  ($self, $c) {
  return $c->redirect_to_action('#home') && $c->detach if $c->user->registered;
  $c->build_view(unregistered_user => $c->user);
}

  sub GET :Action ($self, $c) { return $c->view->set_http_ok }

  sub POST :Action RequestModel(RegistrationRequest) ($self, $c, $request) {    
    return $c->user->register($request) ?
      $c->redirect_to_action('#login') :
        $c->view->set_http_bad_request;
  }

__PACKAGE__->meta->make_immutable; 
