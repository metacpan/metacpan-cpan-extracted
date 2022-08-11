package Example::View::Errors::HTML;

use Moose;
use Example::Syntax;

extends 'Catalyst::View::Errors::HTML';

sub http_404($self, $c, %args) {
  return $c->view('Errors::NotFound', %args);
}

__PACKAGE__->meta->make_immutable;
