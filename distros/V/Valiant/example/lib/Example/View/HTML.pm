package Example::View::HTML;

use Moose;
use Example::Syntax;
use Catalyst::View::Valiant::HTMLBuilder;

sub redirect_to_action ($self, $action, @args) {
  return $self->redirect_to($self->uri_for_action($action, @args));
}

sub the_time  ($self) {
  return P {class=>'timestamp'}, scalar localtime;
}

sub formbuilder_class { 'Example::FormBuilder' }

sub formbuilder_theme($self) {
  return +{ 
    errors_for => +{ class=>'invalid-feedback' },
    label => +{ class=>'form-label' },
    input => +{ class=>'form-control', errors_classes=>'is-invalid' },
    date_field => +{ class=>'form-control', errors_classes=>'is-invalid' },
    password => +{ class=>'form-control', errors_classes=>'is-invalid' },
    submit => +{ class=>'btn btn-lg btn-success btn-block' },
    button => +{ class=>'btn btn-lg btn-primary btn-block' },
    text_area => +{ class=>'form-control', errors_classes=>'is-invalid' },
    checkbox => +{ class=>'form-check-input', errors_classes=>'is-invalid' },
    collection_radio_buttons => +{errors_classes=>'is-invalid'},
    collection_checkbox => +{errors_classes=>'is-invalid'},
    collection_select => +{class=>'form-control', errors_classes=>'is-invalid'},
    select => +{class=>'form-control', errors_classes=>'is-invalid'},
    radio_buttons => +{errors_classes=>'is-invalid'},
    radio_button => +{class=>'custom-control-input', errors_classes=>'is-invalid'},
    model_errors => +{ class=>'alert alert-danger', role=>'alert' },
    form_has_errors => +{ class=>'alert alert-danger', role=>'alert' },
    attributes => {
      password => {
        password => { autocomplete=>'new-password' }
      }
    },
  };
}

__PACKAGE__->meta->make_immutable;