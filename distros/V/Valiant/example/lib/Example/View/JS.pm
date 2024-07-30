package Example::View::JS;

use Moose;
use Example::Syntax;
use Catalyst::View::Valiant::HTMLBuilder;

sub redirect_to_action ($self, $action, @args) {
  my $location = $self->ctx->uri($action, @args);
  $self->ctx->response->content_type('text/javascript');
  $self->ctx->response->body("window.location = '$location';");
}

sub render($self, $c) {
  my $response_body = $self->data_template;
  $c->log->debug($response_body) if $ENV{DEBUG_JAVASCRIPT};
  return $response_body;
}

__PACKAGE__->config(content_type=>'application/javascript');