package Example::Model::ContactsQuery;

use Moo;
use CatalystX::QueryModel;
use Valiant::Validations;
use Example::Syntax;

extends 'Catalyst::Model';
namespace 'contact';

has page => (is=>'ro', property=>1); 
validates page => (numericality=>'positive_integer', allow_blank=>1, strict=>1);

sub BUILD($self, $args) { $self->validate }

1;
