package View::Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub root :Chained('/') PathPart('') CaptureArgs(0) {
  my ($self, $c) = @_;
  $c->view(Hello =>
    name => 'John',
  );
} 

  sub test :Chained('root') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->view);
  }

  sub dispatcher :Chained('root') PathPart('') Args(1) {
    my ($self, $c, $name) = @_;
    $c->res->body($c->view->$name);
  }

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
