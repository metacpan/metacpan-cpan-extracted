package Example::Controller::Todos;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

has todo => (is=>'rw');

sub root :Chained(/auth) PathPart('todos') Args(0) Does(Verbs) View(HTML::Todos) RequestModel(TodosQuery) ($self, $c, $q) {
  $c->build_view(
    list => $c->user->request_todos($q),
    todo => my $todo = $c->user->new_todo,
  );
  $self->todo($todo);
}

  sub GET :Action ($self, $c) { return $c->view->set_http_ok }

  sub POST :Action RequestModel(TodoRequest) ($self, $c, $request) {
    $self->todo->set_from_request($request);
    return $self->todo->valid ?
      $c->redirect_to_action('root') :
        $c->view->set_http_bad_request;
  }

__PACKAGE__->meta->make_immutable;
