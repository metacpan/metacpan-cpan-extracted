package Example::View::HTML::Login;
 
use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(fieldset form_for input legend div a link_to),
  -helpers => qw(create_path register_init_path),
  -views => 'HTML::Page';

has 'user' => (is=>'ro', required=>1);
has 'post_login_redirect' => (is=>'rw', predicate=>'has_post_login_redirect');

sub action_link :Renders ($self) {
  return create_path( $self->has_post_login_redirect ?
    +{post_login_redirect=>$self->post_login_redirect} : 
    +{} );
}

sub render($self, $c) {
  html_page page_title => 'Sign In', sub($page) {
    div +{ class=>'col-5 mx-auto' },
      form_for $self->user, +{action=>$self->action_link}, sub ($self, $fb, $u) {
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
        input {if=>$self->has_post_login_redirect, type=>'hidden', name=>'post_login_redirect', value=>$self->post_login_redirect},
        div +{ class=>'text-center' },
          link_to register_init_path(), 'Register', 
      };
    };
}
 
1;
