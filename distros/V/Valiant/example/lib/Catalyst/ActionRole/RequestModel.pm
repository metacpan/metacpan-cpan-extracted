package Catalyst::ActionRole::RequestModel;

use Moose::Role;
 
our $VERSION = '0.001';
 
has request_model => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_request_model');
 
  sub _build_request_model {
    my ($self) = @_;
    my ($model) = @{$self->attributes->{RequestModel}||['']};
    return $model;
  }
 
around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  my $model = $c->model($self->request_model, $c->request->data); 
  return $self->$orig($controller, $ctx, @args, $model);
};
 
1
