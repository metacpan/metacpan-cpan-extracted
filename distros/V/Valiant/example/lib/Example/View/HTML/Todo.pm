package Example::View::HTML::Todo;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'fieldset';

extends 'Example::View::HTML';

has 'todo' => (is=>'ro', required=>1 );

sub status_options($self) {
  return [qw/
    active
    completed
    archived
  /];
}

sub render($self, $c) {
  $c->view('HTML::Layout' => page_title=>'Homepage', sub($layout) {
    $c->view('HTML::Navbar' => active_link=>'/todos'),
    $c->view('HTML::Form', $self->todo, +{style=>'width:35em; margin:auto'}, sub ($fb) {
      fieldset [
        $fb->legend,
        div +{ class=>'form-group' },
          $fb->model_errors(+{class=>'alert alert-danger', role=>'alert'}),
          div +{ class=>'form-row' }, [
            div +{ class=>'col form-group' }, [
              $fb->label('title'),
              $fb->input('title', +{ class=>'form-control', errors_classes=>'is-invalid' }),
              $fb->errors_for('ztitleip', +{ class=>'invalid-feedback' }),
            ],
            div +{ class=>'col form-group' }, [
              $fb->label('status'),
              $fb->select('status', $self->status_options, id=>'name', +{ include_blank=>1, class=>'form-control', errors_classes=>'is-invalid'}),
              $fb->errors_for('status', +{ class=>'invalid-feedback' }),
            ],
          ],
        $fb->submit('Update Todo', +{class=>'btn btn-lg btn-primary btn-block'}),
      ],
    }),
  });
}

__PACKAGE__->meta->make_immutable();
