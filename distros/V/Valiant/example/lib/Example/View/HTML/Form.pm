package Example::View::HTML::Form;

use Moose;
use Example::Syntax;
use Valiant::HTML::Form 'form_for';
 
extends 'Example::View::HTML';

has 'model' => (is=>'ro', required=>1);
has 'options' => (is=>'ro', required=>1);

sub prepare_build_args($class, $c, $model, $options={}, @args) {
  return model => $model, options => $options, @args;
};

sub execute_code_callback {
  my ($self, @args) = @_;
  return form_for $self->model, +{ 
    action => $self->ctx->req->uri, 
    csrf_token => $self->ctx->csrf_token,
    %{$self->options}, 
  }, $self->code;
}

sub render($self, $c, $content) {
  return $content;
}

1;
