package Example::View::HTML::Register::Build;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML;

sub render($self, $c) {
  return $self->view('HTML::Page', { page_title=>'Register' }, sub($page) {
    Div +{ class=>'col-5 mx-auto' },
      $self->view('HTML::Register::Form');
  }),
}

__PACKAGE__->meta->make_immutable;