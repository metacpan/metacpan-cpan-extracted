package Example::View::HTML::Login;
 
use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder qw(fieldset input legend div a);

extends 'Example::View::HTML';
  
has 'user' => (is=>'ro', required=>1);
has 'post_login_redirect' => (is=>'rw', predicate=>'has_post_login_redirect');

__PACKAGE__->views(
  layout => 'HTML::Layout',
  form_for => 'HTML::FormFor',
);

sub render($self, $c) {
  $self->layout(page_title => 'Sign In', sub($layout) {
    $self->form_for($self->user, +{action_bak=>$c->uri('#login'), class=>'mx-auto', style=>'width:25em'}, sub ($ff, $fb, $u) {
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
      input {cond=>$self->has_post_login_redirect, type=>'hidden', name=>'post_login_redirect', value=>$self->post_login_redirect},
      div +{ class=>'text-center' },
        a +{ href=>"/register" }, 'Register';    
    });
  });
}
 
__PACKAGE__->meta->make_immutable();
