package Example::View::HTML::Register;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'fieldset';

extends 'Example::View::HTML';

has 'unregistered_user' => (is=>'ro', required=>1);

sub render($self, $c) {
  $c->view('HTML::Layout', page_title=>'Homepage', sub($layout) {
    $c->view('HTML::Form', $self->unregistered_user, +{style=>'width:35em; margin:auto'}, sub ($fb) {
      fieldset [
        $fb->legend,
        div +{ class=>'form-group' },
          $fb->model_errors(+{class=>'alert alert-danger', role=>'alert'}),
        div +{ class=>'form-group' }, [
          $fb->label('first_name'),
          $fb->input('first_name', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('first_name', +{ class=>'invalid-feedback' }),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('last_name'),
          $fb->input('last_name', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('last_name', +{ class=>'invalid-feedback' }),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('username'),
          $fb->input('username', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('username', +{ class=>'invalid-feedback' }),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('password'),
          $fb->password('password', +{ autocomplete=>'new-password', class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('password', +{ class=>'invalid-feedback' }),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('password_confirmation'),
           $fb->password('password_confirmation', +{ class=>'form-control', errors_classes=>'is-invalid' }),
          $fb->errors_for('password_confirmation', +{ class=>'invalid-feedback' }),
        ],
        $fb->submit('Register for Account', +{class=>'btn btn-lg btn-primary btn-block'}),
      ],
    }),
  });
}

__PACKAGE__->meta->make_immutable();
