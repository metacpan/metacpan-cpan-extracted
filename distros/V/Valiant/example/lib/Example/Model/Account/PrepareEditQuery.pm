package Example::Model::Account::PrepareEditQuery;

use Moo;
use CatalystX::QueryModel;
use Valiant::Validations;
use Example::Syntax;

extends 'Catalyst::Model';
namespace '';

has replace => (is=>'ro', property=>1, predicate=>'has_replace'); 

validates replace => (
  inclusion => [
    '#edit_account',
  ], 
  allow_blank=>1,
  strict=>1
);

sub BUILD($self, $args) { $self->validate }

1;