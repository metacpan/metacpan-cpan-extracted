package Example::View::HTML::Todos::Form;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset form_for),
  -util => qw(path);

has 'todo' => (is=>'ro', required=>1, handles=>[qw/status_options/] );

sub create_or_update_path  :Renders ($self)  {
  return $self->todo->in_storage ?
   path('update', [$self->todo->id]) :
    path('create'); 
}

sub render($self, $c) {
  form_for $self->todo, +{action=>$self->create_or_update_path}, sub ($self, $fb, $todo) {
    fieldset [
      div +{ if=>$fb->successfully_updated, class=>'alert alert-success', role=>'alert' }, 'Successfully Saved!',
      $fb->legend,
      div +{ class=>'form-group' },
        $fb->model_errors(+{show_message_on_field_errors=>'Please fix the listed errors.'}),
      div +{ class=>'form-row' }, [
        div +{ class=>'col form-group col-9' }, [
          $fb->label('title'),
          $fb->input('title'),
          $fb->errors_for('title'),
        ],
        div +{ class=>'col form-group col-3' }, [
          $fb->label('status'),
          $fb->select('status', $self->status_options, +{ include_blank=>1}),
          $fb->errors_for('status'),
        ],
      ],
      $fb->submit(),
      a {href=>path('list'), class=>'btn btn-secondary btn-lg btn-block'}, 'Return to Todo List',
    ],
  },
}

1;