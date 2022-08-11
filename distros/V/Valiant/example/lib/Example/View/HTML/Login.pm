package Example::View::HTML::Login;
 
use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder qw(fieldset legend div a);

extends 'Example::View::HTML';
  
has 'user' => (is=>'ro', required=>1);

sub render($self, $c) {
  $c->view('HTML::Layout' => page_title=>'Sign In', sub($layout) {
    $c->view('HTML::Form', $self->user, +{style=>'width:20em; margin:auto'}, sub ($fb) {
      fieldset [
        legend 'Sign In',
        div +{ class=>'form-group' },
          $fb->model_errors(+{class=>'alert alert-danger', role=>'alert'}),
        div +{ class=>'form-group' }, [
          $fb->label('username'),
          $fb->input('username', +{class=>'form-control'}),
        ],
        div +{ class=>'form-group' }, [
          $fb->label('password'),
          $fb->password('password', +{class=>'form-control'}),
        ],
        $fb->submit('Sign In', +{class=>'btn btn-lg btn-primary btn-block'}),
      ],
      div +{ class=>'text-center' },
        a +{ href=>"/register" }, 'Register';    
    });
  });
}
 
__PACKAGE__->meta->make_immutable();
