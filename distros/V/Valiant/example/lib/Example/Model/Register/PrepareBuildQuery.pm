package Example::Model::Register::PrepareBuildQuery;

use Moo;
use CatalystX::QueryModel;
use Valiant::Validations;
use Example::Syntax;

extends 'Catalyst::Model';
namespace '';

has replace => (is=>'ro', property=>1, predicate=>'has_replace'); 

validates replace => (
  inclusion => [
    '#new_registration',
    '#registration_first_name_form_group',
    '#registration_last_name_form_group',
    '#registration_username_form_group',
    '#registration_password_form_group',
    '#registration_password_confirmation_form_group',
    '#registration_pw_confirm',
  ], 
  allow_blank=>1,
  strict=>1
);

sub BUILD($self, $args) { $self->validate }

1;