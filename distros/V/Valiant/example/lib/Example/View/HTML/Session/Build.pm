package Example::View::HTML::Session::Build;
 
use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML;

sub render($self, $c) {
  $self->view('HTML::Page', {page_title => 'Sign In'}, sub($page) {
    Div +{ class=>'col-5 mx-auto' },
      $self->view('HTML::Session::Form');
  });
};

__PACKAGE__->meta->make_immutable;
