package Example::Utils::FormBuilder;

use Moo;
use Example::Syntax;

extends 'Valiant::HTML::FormBuilder';

sub successfully_updated($self) {
  return $self->model->validated && !$self->model->has_errors;
}

sub default_theme($self) {
  return +{ 
    errors_for => +{ class=>'invalid-feedback' },
    label => +{ class=>'form-label' },
    input => +{ class=>'form-control', errors_classes=>'is-invalid' },
    password => +{ class=>'form-control', errors_classes=>'is-invalid' },
    submit => +{ class=>'btn btn-lg btn-primary btn-block' },
    button => +{ class=>'btn btn-lg btn-primary btn-block' },
    text_area => +{ class=>'form-control' },
    model_errors => +{ class=>'alert alert-danger', role=>'alert', show_message_on_field_errors=>'Please fix the listed errors.' },
    attributes => {
      password => {
        password => { autocomplete=>'new-password' }
      }
    },
  };
}

1;
