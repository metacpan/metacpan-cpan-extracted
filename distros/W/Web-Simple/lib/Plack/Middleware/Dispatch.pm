package Plack::Middleware::Dispatch;

use Moo;

extends 'Web::Dispatch';

has app => (is => 'ro', writer => '_set_app');

sub wrap {
  my ($self, $app, @args) = @_;
  if (ref $self) {
    $self->_set_app($app);
  } else {
    $self = $self->new({ app => $app, @args });
  }
  return $self->to_app;
}

1;
