package Example::Model::Todos::SearchQuery;

use Moo;
use CatalystX::QueryModel;
use Valiant::Validations;
use Example::Syntax;

extends 'Catalyst::Model';
namespace 'todo';

has status => (is=>'ro', property=>1, default=>'all'); 
has page => (is=>'ro', property=>1, default=>1); 

validates status => (inclusion=>[qw/all active completed/], allow_blank=>1, strict=>1);
validates page => (numericality=>'positive_integer', allow_blank=>1, strict=>1);

sub BUILD($self, $args) { $self->validate }

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
