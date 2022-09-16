package Example::View::HTML::Register;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'a', 'fieldset';

extends 'Example::View::HTML';

has 'registration' => (is=>'ro', required=>1, handles=>[qw/form/]);

__PACKAGE__->views(
  layout => 'HTML::Layout',
);

sub render($self, $c) {
  $self->layout( page_title=>'Homepage', sub($layout) {
    $self->form(sub ($reg, $fb) {
      fieldset [
        $fb->legend,
        map { div +{ class=>'form-group' }, $_ }
          $fb->model_errors,
          $reg->first_name,
          $reg->last_name,
          $reg->username,
          $reg->password,
          $reg->password_confirmation,
          $fb->submit('Register for Account'),
      ],
      div { class=>'text-center' }, a { href=>'/login' }, "Login to existing account."
    }),
  });
}

__PACKAGE__->meta->make_immutable();
