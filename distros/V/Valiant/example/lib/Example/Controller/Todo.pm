package Example::Controller::Todo;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

has todo => (is=>'rw');

sub root :Chained(/auth) PathPart('todos') Args(1) Does(Verbs) View(HTML::Todo) ($self, $c, $id) {
  $self->todo($c->user->todos->find($id) ||
    return $c->detach_error(404, +{error=>"Todo id $id not found"}));
  $c->build_view(todo=>$self->todo);
}

  sub GET :Action ($self, $c) { return $c->view->set_http_ok }

  sub PATCH :Action RequestModel(TodoRequest) ($self, $c, $request) {
    $self->todo->set_from_request($request);
    return $self->todo->valid ?
      $c->redirect_to_action('/todos/root') :
        $c->view->set_http_bad_request
  }

__PACKAGE__->meta->make_immutable;

