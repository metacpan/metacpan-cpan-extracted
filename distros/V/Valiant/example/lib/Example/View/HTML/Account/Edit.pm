package Example::View::HTML::Account::Edit;

use CatalystX::Moose;
use Example::Syntax;
use Example::View::HTML;

sub render($self, $c) {
  $self->view('HTML::Page', { page_title=>'Homepage' }, sub($page) {
    $self->view('HTML::Navbar', { active_link=>'account_details' }),
    Div {class=>"col-5 mx-auto"},
      $self->view('HTML::Account::Form');
  });
}

__PACKAGE__->meta->make_immutable;