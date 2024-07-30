package Example::Controller::Time;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub start : Path('start') {
  my ($self, $c) = @_;
  $c->response->body($c->model('Times::StartTime'));
}

sub now : Path('now') {
  my ($self, $c) = @_;
  $c->response->body($c->model('Times::NowTime'));
}

1;
