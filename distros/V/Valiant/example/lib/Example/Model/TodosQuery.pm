package Example::Model::TodosQuery;

use Moo;
use CatalystX::QueryModel;
use Valiant::Validations;
use Example::Syntax;

extends 'Catalyst::Model';
namespace 'todo';

has status => (is=>'ro', property=>1); 
has page => (is=>'ro', property=>1); 

validates status => (inclusion=>[qw/all active completed/], allow_blank=>1, strict=>1);
validates page => (numericality=>'positive_integer', allow_blank=>1, strict=>1);

sub BUILD($self, $args) { $self->validate }

1;
