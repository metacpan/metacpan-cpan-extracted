package Example::View::Errors::NotFound;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'h1', 'p';

extends 'Example::View::HTML';

has 'status_code' => (is=>'ro', required=>1);
has 'message' => (is=>'ro', required=>1);
has 'title' => (is=>'ro', required=>1);
has 'uri' => (is=>'ro', required=>1);

sub render($self, $c) {
  $c->view('HTML::Layout' => page_title=>$self->title, sub($layout) {
    div {class=>'cover'}, [
      h1 "@{[ $self->status_code ]}: @{[ $self->title ]}",
      p {class=>'lead'}, $self->message,
    ];
  });
}

__PACKAGE__->meta->make_immutable;
