package Example::View::HTML;

use Moose;
use Valiant::HTML::SafeString 'concat';
use Valiant::HTML::Form 'form_for';
use Example::Syntax;

extends 'Catalyst::View::BasePerRequest';

sub flatten_rendered($self, @rendered) {
  return concat grep { defined($_) } @rendered;
}

sub link($self, @args) {
  return $self->ctx->uri(@args);
}

__PACKAGE__->config(
  content_type=>'text/html',
);
