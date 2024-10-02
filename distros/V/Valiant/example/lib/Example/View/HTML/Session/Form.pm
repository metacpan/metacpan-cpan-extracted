package Example::View::HTML::Session::Form;
 
use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML
  qw(form_for link_to uri);

has 'person' => (is=>'ro', shared=>1);

sub render($self, $c) {
  $self->form_for('person', {data=>{remote=>1}}, sub ($self, $fb, $person) {
    Fieldset [
      Legend 'Sign In',
      $fb->model_errors(),
      Div +{ class=>'form-group' }, [
        $fb->label('username'),
        $fb->input('username'),
      ],
      Div +{ class=>'form-group' }, [
        $fb->label('password'),
        $fb->password('password'),
      ],
      $fb->submit('Sign In'),
    ],
    Div +{ class=>'text-center' },
      $self->link_to($self->uri('/register/build'), 'Register'), 
  });
};

__PACKAGE__->meta->make_immutable;
