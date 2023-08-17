package Example::View::HTML::Session::Build;
 
use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(fieldset form_for input legend div a link_to),
  -helpers => qw(path),
  -views => 'HTML::Page';

has 'user' => (is=>'ro', required=>1);

sub render($self, $c) {
  html_page page_title => 'Sign In', sub($page) {
    div +{ class=>'col-5 mx-auto' },
      form_for $self->user, +{action=>path('/session/create')}, sub ($self, $fb, $u) {
        fieldset [
          legend 'Sign In',
          div +{ class=>'form-group' },
            $fb->model_errors(),
          div +{ class=>'form-group' }, [
            $fb->label('username'),
            $fb->input('username'),
          ],
          div +{ class=>'form-group' }, [
            $fb->label('password'),
            $fb->password('password'),
          ],
          $fb->submit('Sign In'),
        ],
        div +{ class=>'text-center' },
          link_to path('/register/build'), 'Register', 
      };
    };
}
 
1;
