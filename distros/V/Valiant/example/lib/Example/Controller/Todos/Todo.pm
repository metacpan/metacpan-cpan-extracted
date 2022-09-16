package Example::Controller::Todos::Todo;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub todo :Chained(../todos) PathPart('') CaptureArgs(1) ($self, $c, $id, $collection) {
  my $todo = $collection->find($id) || return $c->detach_error(404, +{error=>"Todo id $id not found"});
  $c->next_action($todo);
}

  sub edit :Chained(todo) PathPart('') Args(0) Verbs(GET, PATCH) Name(TodoEdit) ($self, $c, $todo) {
    $c->view('HTML::Todo', todo=>$todo);
    $c->next_action($todo);
  }
  
  sub PATCH :Action RequestModel(TodoRequest) ($self, $c, $request, $todo) {
    $todo->set_from_request($request);
    return $todo->valid ?
      $c->redirect_to_action('#TodosList') :
        $c->view->set_http_bad_request
  }

__PACKAGE__->meta->make_immutable;
