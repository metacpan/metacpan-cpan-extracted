package Example::Model::TodosQuery::Session;

use Moo;
use Example::Syntax;
use Hash::Merge 'merge';

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has status => (is=>'ro', required=>1, default=>'all'); 
has page => (is=>'ro', required=>1, default=>1); 

sub build_per_context_instance($self, $c, $q) {
  my $args = merge( $q->nested_params, ($c->model('Session')->todo_query //+{}) );
  $c->model('Session')->todo_query($args);
  return ref($self)->new(%$args);
}

sub status_all($self) {
  return $self->status eq 'all' ? 1:0;
}

sub status_active($self) {
  return $self->status eq 'active' ? 1:0;
}

sub status_completed($self) {
  return $self->status eq 'completed' ? 1:0;
}

sub status_is($self, $value) {
  return $self->status eq $value ? 1:0;
}

1;
