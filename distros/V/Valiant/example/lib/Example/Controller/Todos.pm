package Example::Controller::Todos;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;
use Types::Standard qw(Int);

extends 'Example::Controller';

# /todos/...
sub root :At('$path_end/...') Via('../protected') ($self, $c, $user) {
  $c->action->next(my $todos = $user->todos);
}

  # /todos/...
  sub search :At('/...') Via('root') QueryModel ($self, $c, $todos, $todo_query) {
    $todos = $todos->filter_by_request($todo_query);
    $c->action->next($todos);
  }

    # GET /todos
    sub list :Get('') Via('search') ($self, $c, $todos) {
      return $self->view(
        list => $todos,
        todo => $todos->new_todo,
      );
    }

  # /todos/...
  sub prepare_build :At('/...') Via('search') ($self, $c, $todos) {

    $self->view_for('list',
      list => $todos,
      todo => my $new_todo = $todos->new_todo
    );
    $c->action->next($new_todo);
  }

    # GET /todos/new
    sub build :Get('new') Via('prepare_build') ($self, $c, $new_todo) { return }

    # POST /todos/
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $new_todo, $bm) {
      return $c->view->clear_todo && $c->view->set_list_to_last_page
        if $new_todo->set_from_request($bm)->valid;
    }

  # /todos/{:Int}/...
  sub find :At('{:Int}/...') Via('root') ($self, $c, $collection, $id) {
    my $todo = $collection->find($id) // $c->detach_error(404, +{error=>"Todo id $id not found"});
    $c->action->next($todo);
  }

    # /todos/{:Int}/...
    sub prepare_edit :At('/...') Via('find') ($self, $c, $todo) {
      $self->view_for('edit', todo => $todo);
      $c->action->next($todo);
    }

      # GET /todos/{:Int}/edit
      sub edit :Get('edit') Via('prepare_edit') ($self, $c, $todo) { return }
    
      # PATCH /todos/{:Int}
      sub update :Patch('') Via('prepare_edit') BodyModelFor('create') ($self, $c, $todo, $bm) {
        return $todo->set_from_request($bm);
      }

__PACKAGE__->meta->make_immutable;
