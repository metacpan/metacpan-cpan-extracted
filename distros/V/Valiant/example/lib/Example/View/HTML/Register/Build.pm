package Example::View::HTML::Register::Build;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset form_for),
  -util => qw( session_build_uri ),
  -views => 'HTML::Page';

has 'registration' => (is=>'ro', required=>1);

sub render($self, $c) {
  html_page page_title=>'Homepage', sub($page) {
    div +{ class=>'col-5 mx-auto' },
    form_for $self->registration, sub ($self, $fb, $registration) {
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
      div { class=>'text-center' }, a { href=>session_build_uri }, 'Login to existing account.',
    },
  },
}

1;
