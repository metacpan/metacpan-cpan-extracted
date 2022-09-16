package Example::Model::TodosQuery::Session;

use Moo;
use Example::Syntax;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has status => (is=>'ro', required=>1, default=>'all'); 
has page => (is=>'ro', required=>1, default=>1); 

sub build_per_context_instance($self, $c, $q) {
  my %request_args = %{ $q->nested_params };
  my %session_args = %{ $c->model('Session')->todo_query //+{} };
    
  foreach my $key(qw/page status/) {
    $request_args{$key} //= $session_args{$key} if exists($session_args{$key}) && defined($session_args{$key});
    $session_args{$key} = $request_args{$key} if exists($request_args{$key}) && defined($request_args{$key});
  }

  $c->model('Session')->todo_query(\%session_args);

  return ref($self)->new(%request_args);
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

