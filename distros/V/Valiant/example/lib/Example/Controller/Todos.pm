package Example::Controller::Todos;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub todos :Chained(../auth) CaptureArgs(0) ($self, $c, $user) {
  my $collection = $user->todos;
  $c->next_action($collection);
}

  sub list :Chained(todos) PathPart('') Args(0) Verbs(GET,POST) RequestModel(TodosQuery) Name(TodosList) ($self, $c, $q, $collection) {
    my $sessioned_query = $c->model('TodosQuery::Session', $q);
    $c->view('HTML::Todos',
      todo => my $todo = $c->user->new_todo,
      list => $collection->filter_by_request($sessioned_query),
    );
    $c->next_action($todo);
  }

    sub POST :Action RequestModel(TodoRequest) ($self, $c, $request, $todo) {
      $todo->set_from_request($request);
      return $todo->valid ?
        $c->redirect_to_action('#TodoEdit', [$todo->id]) :
          $c->view->set_http_bad_request;
    }

__PACKAGE__->meta->make_immutable;
