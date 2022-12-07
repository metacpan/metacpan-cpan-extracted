package Example::View::HTML::Register;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'a', 'fieldset';

extends 'Example::View::HTML';

has 'registration' => (is=>'ro', required=>1);

__PACKAGE__->views(
  layout => 'HTML::Layout',
  form_for => 'HTML::FormFor',
);

sub render($self, $c) {
  $self->layout( page_title=>'Homepage', sub($layout) {
    $self->form_for($self->registration, +{style=>'width:35em; margin:auto'}, sub ($ff, $fb, $registration) {
      fieldset [
        $fb->legend,
        div +{ class=>'form-group' },
          $fb->model_errors(+{show_message_on_field_errors=>'Please fix validation errors'}),
        div +{ class=>'form-group' }, [
          $fb->label('first_name'),
          $fb->input('first_name'),
          $fb->errors_for('first_name'),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('last_name'),
          $fb->input('last_name'),
          $fb->errors_for('last_name'),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('username'),
          $fb->input('username'),
          $fb->errors_for('username'),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('password'),
          $fb->password('password'),
          $fb->errors_for('password'),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('password_confirmation'),
          $fb->password('password_confirmation'),
          $fb->errors_for('password_confirmation'),
        ],
      ],
      fieldset $fb->submit('Register for Account'),
      div { class=>'text-center' }, a { href=>'/login' }, 'Login to existing account.',
    }),
  }),
}

__PACKAGE__->meta->make_immutable();
